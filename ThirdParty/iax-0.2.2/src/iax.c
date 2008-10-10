/*
 * libiax: An implementation of Inter-Asterisk eXchange
 *
 * Copyright (C) 2001, Linux Support Services, Inc.
 *
 * Mark Spencer <markster@linux-support.net>
 *
 * This program is free software, distributed under the terms of
 * the GNU Lesser (Library) General Public License
 */
 
#ifdef	WIN32

#include <string.h>
#include <process.h>
#include <windows.h>
#include <winsock.h>
#include <time.h>
#include <stdlib.h>
#include <malloc.h>
#include <stdarg.h>
#include <stdio.h>
#include <fcntl.h>
#include <io.h>
#include <errno.h>
#include <winpoop.h>

#else

#include <netdb.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <sys/time.h>
#include <stdlib.h>
#include <string.h>
#ifndef IPHONE
#include <malloc.h>
#endif
#include <stdarg.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#ifndef IPHONE
#include <error.h>
#endif
#include <sys/select.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <time.h>
#endif

#include "frame.h" 
#include "iax-client.h"
#include "iax.h"
#include "md5.h"

#ifdef SNOM_HACK
/* The snom phone seems to improperly execute memset in some cases */
#define MEMSET snom_memset
static void *snom_memset(void *s, int c, size_t n)
{
	char *sc = s;
	size_t x;
	for (x=0;x<n;x++)
		sc[x] = c;
	return s;
}
#else
#define MEMSET memset
#endif

#define IAX_EVENT_REREQUEST	999
#define IAX_EVENT_TXREPLY	1000
#define IAX_EVENT_TXREJECT	1001
#define IAX_EVENT_TXACCEPT  1002
#define IAX_EVENT_TXREADY	1003

/* Define Voice Smoothing to try to make some judgements and adjust timestamps
   on incoming packets to what they "ought to be" */

#define VOICE_SMOOTHING
#undef VOICE_SMOOTHING

/* Define Drop Whole Frames to make IAX shrink its jitter buffer by dropping entire
   frames rather than simply delivering them faster.  Dropping encoded frames, 
   before they're decoded, usually leads to better results than dropping 
   decoded frames. */

#define DROP_WHOLE_FRAMES

#define MIN_RETRY_TIME 10
#define MAX_RETRY_TIME 10000
#define MEMORY_SIZE 100

#define TRANSFER_NONE  0
#define TRANSFER_BEGIN 1
#define TRANSFER_READY 2

/* No more than 4 seconds of jitter buffer */
static int max_jitterbuffer = 4000;
/* No more than 50 extra milliseconds of jitterbuffer than needed */
static int max_extra_jitterbuffer = 50;
/* To use or not to use the jitterbuffer */
static int iax_use_jitterbuffer = 1;

/* UDP Socket (file descriptor) */
static int netfd = -1;

/* Max timeouts */
static int maxretries = 10;

/* Dropcount (in per-MEMORY_SIZE) usually percent */
static int iax_dropcount = 3;

struct iax_session {
	/* Is voice quelched (e.g. hold) */
	int quelch;
	/* Last received voice format */
	int voiceformat;
	/* Last transmitted voice format */
	int svoiceformat;
	/* Last received timestamp */
	unsigned int last_ts;
	/* Last transmitted timestamp */
	unsigned int lastsent;
	/* Last transmitted voice timestamp */
	unsigned int lastvoicets;
	/* Our last measured ping time */
	unsigned int pingtime;
	/* Address of peer */
	struct sockaddr_in peeraddr;
	/* Our call number */
	int callno;
	/* Peer's call number */
	int peercallno;
	/* Our last sent sequence number */
	unsigned short oseqno;
	/* Our last received incoming sequence number */
	unsigned short iseqno;
	/* Peer supported formats */
	int peerformats;
	/* Time value that we base our transmission on */
	struct timeval offset;
	/* Time value we base our delivery on */
	struct timeval rxcore;
	/* History of lags */
	int history[MEMORY_SIZE];
	/* Current base jitterbuffer */
	int jitterbuffer;
	/* Informational jitter */
	int jitter;
	/* Measured lag */
	int lag;
	/* Current link state */
	int state;
	/* Peer name */
	char peer[MAXSTRLEN];
	/* Default Context */
	char context[MAXSTRLEN];
	/* Caller ID if available */
	char callerid[MAXSTRLEN];
	/* DNID */
	char dnid[MAXSTRLEN];
	/* Requested Extension */
	char exten[MAXSTRLEN];
	/* Expected Username */
	char username[MAXSTRLEN];
	/* Expected Secret */
	char secret[MAXSTRLEN];
	/* permitted authentication methods */
	char methods[MAXSTRLEN];
	/* MD5 challenge */
	char challenge[12];
#ifdef VOICE_SMOOTHING
	unsigned int lastts;
#endif
	/* Refresh if applicable */
	int refresh;
	
	/* Transfer stuff */
	struct sockaddr_in transfer;
	int transferring;
	int transfercallno;
	
	/* For linking if there are multiple connections */
	struct iax_session *next;
};

struct iax_frame {
	/* Information for where to send this */
	struct iax_session *session;
	/* What to send */
	void *data;
	/* How long is it */
	int datalen;
	/* How many retries have we done? */
	int retries;
	/* How long to wait for a retry? */
	int retrytime;
	/* Is this a special transfer packet? */
	int transferpacket;
	/* Easy Linking */
	struct iax_frame *next;
};

#ifdef	WIN32

void gettimeofday(struct timeval *tv, struct timezone *tz);

#define	snprintf _snprintf

#endif

char iax_errstr[256];

static int sformats = 0;

#define IAXERROR snprintf(iax_errstr, sizeof(iax_errstr), 

#ifdef DEBUG_SUPPORT

#ifdef DEBUG_DEFAULT
static int debug = 1;
#else
static int debug = 0;
#endif

/* This is a little strange, but to debug you call DEBU(G "Hello World!\n"); */ \
#ifdef	WIN32
#define G __FILE__, __LINE__,
#else
#define G __FILE__, __LINE__, __PRETTY_FUNCTION__, 
#endif

#define DEBU __debug 
#ifdef	WIN32
static int __debug(char *file, int lineno, char *fmt, ...) 
{
	va_list args;
	va_start(args, fmt);
	if (debug) {
		fprintf(stderr, "%s line %d: ", file, lineno);
		vfprintf(stderr, fmt, args);
	}
	va_end(args);
	return 0;
}
#else
static int __debug(char *file, int lineno, char *func, char *fmt, ...) 
{
	va_list args;
	va_start(args, fmt);
	if (debug) {
		fprintf(stderr, "%s line %d in %s: ", file, lineno, func);
		vfprintf(stderr, fmt, args);
	}
	va_end(args);
	return 0;
}
#endif
#else /* No debug support */

#ifdef	WIN32
#define	DEBU
#else
#define DEBU(...)
#endif
#define G
#endif

struct iax_sched {
	/* These are scheduled things to be delivered */
	struct timeval when;
	/* If event is non-NULL then we're delivering an event */
	struct iax_event *event;
	/* If frame is non-NULL then we're transmitting a frame */
	struct iax_frame *frame;
	/* Easy linking */
	struct iax_sched *next;
};

#ifdef	WIN32

void bzero(void *b, size_t len)
{
	MEMSET(b,0,len);
}

#endif

static struct iax_sched *schedq = NULL;
static struct iax_session *sessions = NULL;
static int callnums = 1;

static int iax_sched_event(struct iax_event *event, struct iax_frame *frame, int ms)
{

	/* Schedule event to be delivered to the client
	   in ms milliseconds from now, or a reliable frame to be retransmitted */
	struct iax_sched *sched, *cur, *prev = NULL;
	
	if (!event && !frame) {
		DEBU(G "No event, no frame?  what are we scheduling?\n");
		return -1;
	}
	

	sched = (struct iax_sched*)malloc(sizeof(struct iax_sched));
	bzero(sched, sizeof(struct iax_sched));
	if (sched) {
		gettimeofday(&sched->when, NULL);
		sched->when.tv_sec += (ms / 1000);
		ms = ms % 1000;
		sched->when.tv_usec += (ms * 1000);
		if (sched->when.tv_usec > 1000000) {
			sched->when.tv_usec -= 1000000;
			sched->when.tv_sec++;
		}
		sched->event = event;
		sched->frame = frame;
		/* Put it in the list, in order */
		cur = schedq;
		while(cur && ((cur->when.tv_sec < sched->when.tv_sec) || 
					 ((cur->when.tv_usec <= sched->when.tv_usec) &&
					  (cur->when.tv_sec == sched->when.tv_sec)))) {
				prev = cur;
				cur = cur->next;
		}
		sched->next = cur;
		if (prev) {
			prev->next = sched;
		} else {
			schedq = sched;
		}
		return 0;
	} else {
		DEBU(G "Out of memory!\n");
		return -1;
	}
}

int iax_time_to_next_event(void)
{
	struct timeval tv;
	struct iax_sched *cur = schedq;
	int ms, min = 999999999;
	
	/* If there are no pending events, we don't need to timeout */
	if (!cur)
		return -1;
	gettimeofday(&tv, NULL);
	while(cur) {
		ms = (cur->when.tv_sec - tv.tv_sec) * 1000 +
		     (cur->when.tv_usec - tv.tv_usec) / 1000;
		if (ms < min)
			min = ms;
		cur = cur->next;
	}
	if (min < 0)
		min = 0;
	return min;
}

struct iax_session *iax_session_new(void)
{
	struct iax_session *s;
	s = (struct iax_session *)malloc(sizeof(struct iax_session));
	if (s) {
		MEMSET(s, 0, sizeof(struct iax_session));
		/* Initialize important fields */
		s->voiceformat = -1;
		s->svoiceformat = -1;
		/* Default pingtime to 30 ms */
		s->pingtime = 30;
		/* XXX Not quite right -- make sure it's not in use, but that won't matter
	           unless you've had at least 65k calls.  XXX */
		s->callno = callnums++;
		if (callnums > 32767)
			callnums = 1;
		s->peercallno = -1;
		s->next = sessions;
		sessions = s;
	}
	return s;
}

static int iax_session_valid(struct iax_session *session)
{
	/* Return -1 on a valid iax session pointer, 0 on a failure */
	struct iax_session *cur = sessions;
	while(cur) {
		if (session == cur)
			return -1;
		cur = cur->next;
	}
	return 0;
}

static int calc_timestamp(struct iax_session *session, unsigned int ts)
{
	int ms;
	struct timeval tv;
	
	/* If this is the first packet we're sending, get our
	   offset now. */
	if (!session->offset.tv_sec && !session->offset.tv_usec)
		gettimeofday(&session->offset, NULL);

	/* If the timestamp is specified, just use their specified
	   timestamp no matter what.  Usually this is done for
	   special cases.  */
	if (ts)
		return ts;
	
	/* Otherwise calculate the timestamp from the current time */
	gettimeofday(&tv, NULL);
		
	/* Calculate the number of milliseconds since we sent the first packet */
	ms = (tv.tv_sec - session->offset.tv_sec) * 1000 +
		 (tv.tv_usec - session->offset.tv_usec) / 1000;

	/* Never send a packet with the same timestamp since timestamps can be used
	   to acknowledge certain packets */
    	if ((unsigned) ms <= session->lastsent)
		ms = session->lastsent + 1;

	/* Record the last sent packet for future reference */
	session->lastsent = ms;

	return ms;
}

#ifdef DEBUG_SUPPORT
void showframe(struct iax_frame *f, struct iax_full_hdr *fhi, int rx)
{
	char *frames[] = {
		"(0?)",
		"DTMF   ",
		"VOICE  ",
		"VIDEO  ",
		"CONTROL",
		"NULL   ",
		"IAX    ",
		"TEXT   ",
		"IMAGE  ",
		"HTML   "};
	char *iaxs[] = {
		"(0?)",
		"NEW    ",
		"PING   ",
		"PONG   ",
		"ACK    ",
		"HANGUP ",
		"REJECT ",
		"ACCEPT ",
		"AUTHREQ",
		"AUTHREP",
		"INVAL  ",
		"LAGRQ  ",
		"LAGRP  ",
		"REGREQ ",
		"REGAUTH",
		"REGACK ",
		"REGREJ ",
		"REGREL ",
		"VNAK   ",
		"DPREQ  ",
		"DPREP  ",
		"DIAL   ",
		"TXREQ  ",
		"TXCNT  ",
		"TXACC  ",
		"TXREADY",
		"TXREL  ",
		"TXREJ  "
	};
	char *cmds[] = {
		"(0?)",
		"HANGUP ",
		"RING   ",
		"RINGING",
		"ANSWER ",
		"BUSY   ",
		"TKOFFHK ",
		"OFFHOOK" };
	struct iax_full_hdr *fh;
	char retries[20];
	char class2[20];
	char subclass2[20];
	char *class;
	char *subclass;
	if (f) {
		fh = f->data;
		snprintf(retries, sizeof(retries), "%03d", f->retries);
	} else {
		strcpy(retries, "N/A");
		fh = fhi;
	}
	if (!(ntohs(fh->callno) & IAX_FLAG_FULL)) {
		/* Don't mess with mini-frames */
		return;
	}

	if ((fh->type >= sizeof(frames)/sizeof(char *)) || (fh->type < 0)) {
		snprintf(class2, sizeof(class2), "(%d?)", fh->type);
		class = class2;
	} else {
		class = frames[(int)fh->type];
	}
	if (fh->type == AST_FRAME_DTMF) {
		sprintf(subclass2, "%c", fh->csub);
		subclass = subclass2;
	} else if (fh->type == AST_FRAME_IAX) {
		if (fh->csub >= sizeof(iaxs)/sizeof(iaxs[0])) {
			snprintf(subclass2, sizeof(subclass2), "(%d?)", fh->csub);
			subclass = subclass2;
		} else {
			subclass = iaxs[(int)fh->csub];
		}
	} else if (fh->type == AST_FRAME_CONTROL) {
		if (fh->csub > sizeof(cmds)/sizeof(char *)) {
			snprintf(subclass2, sizeof(subclass2), "(%d?)", fh->csub);
			subclass = subclass2;
		} else {
			subclass = cmds[(int)fh->csub];
		}
	} else {
		snprintf(subclass2, sizeof(subclass2), "%d", fh->csub);
		subclass = subclass2;
	}
	if (debug) {
		fprintf(stderr, 
"%s-Frame Retry[%s] -- Seqno: %2.2d  Type: %s Subclass: %s\n", 
	(rx ? "Rx" : "Tx"),
	retries, ntohs(fh->seqno), class, subclass);
		fprintf(stderr, 
"   Timestamp: %05dms  Callno: %4.4d  DCall: %4.4d\n", 
	ntohl(fh->ts),
	ntohs(fh->callno) & ~IAX_FLAG_FULL, (short) ntohs(fh->dcallno));
	}
}
#endif
static int iax_xmit_frame(struct iax_frame *f)
{
	/* Send the frame raw */
#ifdef DEBUG_SUPPORT
	showframe(f, NULL, 0);
#endif

	return sendto(netfd, (const char *) f->data, f->datalen,
#if defined(WIN32) || defined(IPHONE)
		0,
#else
		MSG_DONTWAIT | MSG_NOSIGNAL,
#endif
					f->transferpacket ? 
						(struct sockaddr *)&(f->session->transfer) :
					(struct sockaddr *)&(f->session->peeraddr), sizeof(f->session->peeraddr));
}

static int iax_reliable_xmit(struct iax_frame *f)
{
	struct iax_frame *fc;
	struct iax_full_hdr *fh;
	fh = (struct iax_full_hdr *) f->data;
	if (!fh->type) {
		DEBU(G "Asked to reliably transmit a non-packet.  Crashing.\n");
		*((char *)0)=0;
	}
	fc = (struct iax_frame *)malloc(sizeof(struct iax_frame));
	if (fc) {
		/* Make a copy of the frame */
		memcpy(fc, f, sizeof(struct iax_frame));
		/* And a copy of the data if applicable */
		if (!fc->data || !fc->datalen) {
			IAXERROR "No frame data?");
			DEBU(G "No frame data?\n");
			return -1;
		} else {
			fc->data = (char *)malloc(fc->datalen);
			if (!fc->data) {
				DEBU(G "Out of memory\n");
				IAXERROR "Out of memory\n");
				return -1;
			}
			memcpy(fc->data, f->data, f->datalen);
			iax_sched_event(NULL, fc, fc->retrytime);
			return iax_xmit_frame(fc);
		}
	} else
		return -1;
}

int iax_init(int preferredportno)
{
	int portno = preferredportno;
	struct sockaddr_in sin;
	int sinlen;
	int flags;
	
	if (netfd > -1) {
		/* Sokay, just don't do anything */
		DEBU(G "Already initialized.");
		return 0;
	}
	netfd = socket(AF_INET, SOCK_DGRAM, IPPROTO_IP);
	if (netfd < 0) {
		DEBU(G "Unable to allocate UDP socket\n");
		IAXERROR "Unable to allocate UDP socket\n");
		return -1;
	}
	
	if (preferredportno == 0) 
		preferredportno = IAX_DEFAULT_PORTNO;
		
	if (preferredportno > 0) {
		sin.sin_family = AF_INET;
		sin.sin_addr.s_addr = 0;
		sin.sin_port = htons((short)preferredportno);
		if (bind(netfd, (struct sockaddr *) &sin, sizeof(sin)) < 0) {
			DEBU(G "Unable to bind to preferred port.  Using random one instead.");
		}
	}
	sinlen = sizeof(sin);
	if (getsockname(netfd, (struct sockaddr *) &sin, &sinlen) < 0) {
		close(netfd);
		netfd = -1;
		DEBU(G "Unable to figure out what I'm bound to.");
		IAXERROR "Unable to determine bound port number.");
	}
#ifdef	WIN32
	flags = 1;
	if (ioctlsocket(netfd,FIONBIO,(unsigned long *) &flags)) {
		_close(netfd);
		netfd = -1;
		DEBU(G "Unable to set non-blocking mode.");
		IAXERROR "Unable to set non-blocking mode.");
	}
	
#else
	if ((flags = fcntl(netfd, F_GETFL)) < 0) {
		close(netfd);
		netfd = -1;
		DEBU(G "Unable to retrieve socket flags.");
		IAXERROR "Unable to retrieve socket flags.");
	}
	if (fcntl(netfd, F_SETFL, flags | O_NONBLOCK) < 0) {
		close(netfd);
		netfd = -1;
		DEBU(G "Unable to set non-blocking mode.");
		IAXERROR "Unable to set non-blocking mode.");
	}
#endif
	portno = ntohs(sin.sin_port);
	srand(time(NULL));
	callnums = rand() % 32767 + 1;
	DEBU(G "Started on port %d\n", portno);
	return portno;	
}

static void destroy_session(struct iax_session *session);

static void convert_reply(char *out, unsigned char *in)
{
	int x;
	for (x=0;x<16;x++)
		out += sprintf(out, "%2.2x", (int)in[x]);
}

static unsigned char compress_subclass(int subclass)
{
	int x;
	int power=-1;
	/* If it's 128 or smaller, just return it */
	if (subclass < IAX_FLAG_SC_LOG)
		return subclass;
	/* Otherwise find its power */
	for (x = 0; x < IAX_MAX_SHIFT; x++) {
		if (subclass & (1 << x)) {
			if (power > -1) {
				DEBU(G "Can't compress subclass %d\n", subclass);
				return 0;
			} else
				power = x;
		}
	}
	return power | IAX_FLAG_SC_LOG;
}


int iax_do_event(struct iax_session *session, struct iax_event *event)
{
	struct iax_frame f;
	int left;
	struct hostent *hp;
	unsigned int ts;
	char buf[32768];
	struct iax_full_hdr *fh = (struct iax_full_hdr *)buf;
	struct iax_mini_hdr *mh = (struct iax_mini_hdr *)buf;
	struct MD5Context md5;
	char reply[32];
	char realreply[80];
	char *requeststr = fh->data;

#define MYSNPRINTF snprintf(requeststr + strlen(requeststr), sizeof(buf) - sizeof(struct iax_full_hdr) - strlen(requeststr), 

	bzero(buf, sizeof(buf));

	/* Default some things in the frame */

	f.session = session;
	f.data = buf;
	f.datalen = sizeof(struct iax_full_hdr);
	left = sizeof(buf) - f.datalen;
	f.retries = maxretries;
	f.transferpacket = 0;
	
	/* Assume a full header and default some things */
	fh->callno = htons((short)(session->callno | IAX_FLAG_FULL));
	fh->dcallno = htons((short)session->peercallno);

	/* Calculate timestamp */
	fh->ts = htonl(calc_timestamp(session, 0));
	
	/* Start by using twice the pingtime */
	f.retrytime = session->pingtime * 2;
	if (f.retrytime > MAX_RETRY_TIME)
		f.retrytime = MAX_RETRY_TIME;
	if (f.retrytime < MIN_RETRY_TIME)
		f.retrytime = MIN_RETRY_TIME;
	
	f.next = NULL;

	/* Some sanity checks */

	if (!event) {
		DEBU(G "Event is null?\n");
		IAXERROR "Null event");
		return -1;
	}
	if (!session)
		session = event->session;
	if (!iax_session_valid(session)) {
		DEBU(G "Session invalid for sending event\n");
		IAXERROR "Invalid session for transmitting event");
	}

	/* Send (possibly reliably) the correct frame given the kind
	   of event requested */

	switch(event->etype) {
	case IAX_EVENT_CONNECT:
		/* Connect first */
		hp = gethostbyname(event->event.connect.hostname);
		if (!hp) {
			snprintf(iax_errstr, sizeof(iax_errstr), "Invalid hostname: %s", event->event.connect.hostname);
			return -1;
		}
		memcpy(&session->peeraddr.sin_addr, hp->h_addr, sizeof(session->peeraddr.sin_addr));
		session->peeraddr.sin_port = htons(event->event.connect.portno);
		session->peeraddr.sin_family = AF_INET;
		fh->type = AST_FRAME_IAX;
		fh->csub = IAX_COMMAND_NEW;
		fh->seqno = htons(session->oseqno++);
		if (event->event.connect.exten)
			MYSNPRINTF "exten=%s;", event->event.connect.exten);
		if (event->event.connect.callerid)
			MYSNPRINTF "callerid=%s;", event->event.connect.callerid);		
		if (event->event.connect.dnid)
			MYSNPRINTF "dnid=%s;", event->event.connect.dnid);
		if (event->event.connect.context)
			MYSNPRINTF "context=%s;", event->event.connect.context);
		if (event->event.connect.username)
			MYSNPRINTF "username=%s;", event->event.connect.username);
		if (event->event.connect.language)
			MYSNPRINTF "language=%s;", event->event.connect.language);
		MYSNPRINTF "formats=%d;", sformats);
		MYSNPRINTF "version=%d;", IAX_PROTO_VERSION);
		f.datalen += strlen(requeststr);
		iax_reliable_xmit(&f);
		break;
	case IAX_EVENT_REREQUEST:
		fh->type = AST_FRAME_IAX;
		fh->csub = IAX_COMMAND_REGREQ;
		fh->seqno = htons(session->oseqno++);
		MYSNPRINTF "peer=%s;refresh=%d;", session->peer, session->refresh);
		if (strstr(session->methods, "md5")) {
			MD5Init(&md5);
			MD5Update(&md5, (const unsigned char *) &session->challenge[0], strlen(session->challenge));
			MD5Update(&md5, (const unsigned char *) &session->secret[0], strlen(session->secret));
			MD5Final((unsigned char *) reply, &md5);
			memset(realreply, 0, sizeof(realreply));
			convert_reply(realreply, (unsigned char *) &reply[0]);
			MYSNPRINTF "md5secret=%s;", realreply);
		} else {
			MYSNPRINTF "secret=%s;", session->secret);
		}
		f.datalen += strlen(requeststr);
		iax_reliable_xmit(&f);
		break;
	case IAX_EVENT_REGREQ:
		/* Connect first */
		hp = gethostbyname(event->event.regrequest.server);
		if (!hp) {
			snprintf(iax_errstr, sizeof(iax_errstr), "Invalid hostname: %s", event->event.regrequest.server);
			return -1;
		}
		memcpy(&session->peeraddr.sin_addr, hp->h_addr, sizeof(session->peeraddr.sin_addr));
		session->peeraddr.sin_port = htons(event->event.regrequest.portno);
		session->peeraddr.sin_family = AF_INET;
		fh->type = AST_FRAME_IAX;
		fh->csub = IAX_COMMAND_REGREQ;
		fh->seqno = htons(session->oseqno++);
		if (event->event.regrequest.secret)
			strncpy(session->secret, event->event.regrequest.secret, sizeof(session->secret)-1);
		else
			strcpy(session->secret, "");
		if (event->event.regrequest.peer) {
			MYSNPRINTF "peer=%s;", event->event.regrequest.peer);
			strncpy(session->peer, event->event.regrequest.peer, sizeof(session->peer)-1);
		} else
			strcpy(session->peer, "");
		if (event->event.regrequest.refresh) {
			MYSNPRINTF "refresh=%d;", event->event.regrequest.refresh);		
			session->refresh = event->event.regrequest.refresh;
		} else
			session->refresh = 0;
		f.datalen += strlen(requeststr);
		iax_reliable_xmit(&f);
		break;
	case IAX_EVENT_AUTHRP:
		fh->type = AST_FRAME_IAX;
		fh->csub = IAX_COMMAND_AUTHREP;
		fh->seqno = htons(session->oseqno++);
		if (event->event.authreply.authmethod == IAX_AUTHMETHOD_MD5) {
			snprintf(requeststr, left, "md5secret=%s;", event->event.authreply.reply);
		} else if (event->event.authreply.authmethod == IAX_AUTHMETHOD_PLAINTEXT) {
			snprintf(requeststr, left, "secret=%s;", event->event.authreply.reply);
		} else {
			DEBU(G "Unknown auth method: %d\n", event->event.authreply.authmethod);
			IAXERROR "Invalid authentication method %d\n", event->event.authreply.authmethod);
			return -1;
		}
		f.datalen += strlen(requeststr);
		iax_reliable_xmit(&f);
		break;
	case IAX_EVENT_LAGRP:
		/* Special case -- return the original timestamp in the message instead of our
		   own. */
		fh->type = AST_FRAME_IAX;
		fh->csub = IAX_COMMAND_LAGRP;
		fh->ts = htonl(event->event.lagrq.ts);
		fh->seqno = htons(session->oseqno++);
		iax_reliable_xmit(&f);
		break;
	case IAX_EVENT_DTMF:
		/* Send a DTMF tone as a reliable transmission -- easy */
		fh->type = AST_FRAME_DTMF;
		fh->seqno = htons(session->oseqno++);
		fh->csub = event->event.dtmf.digit;
		iax_reliable_xmit(&f);
		break;
	case IAX_EVENT_RINGA:
		/* Announce that we are ringing */
		fh->type = AST_FRAME_CONTROL;
		fh->seqno = htons(session->oseqno++);
		fh->csub = AST_CONTROL_RINGING;
		iax_reliable_xmit(&f);
		break;
	case IAX_EVENT_HANGUP:
		fh->type = AST_FRAME_IAX;
		fh->seqno = htons(session->oseqno++);
		fh->csub = IAX_COMMAND_HANGUP;
		if (event->event.hangup.byemsg) {
			strncpy(fh->data, event->event.hangup.byemsg, left-1);
			f.datalen += strlen(fh->data);
		}
		/* XXX Not really reliable since we turn right around and kill it XXX */
		iax_reliable_xmit(&f);
		destroy_session(session);
		break;
	case IAX_EVENT_REJECT:
		fh->type = AST_FRAME_IAX;
		fh->seqno = htons(session->oseqno++);
		fh->csub = IAX_COMMAND_REJECT;
		strncpy(fh->data, event->event.reject.reason, left-1);
		f.datalen += strlen(fh->data);
		/* XXX Not really reliable since we turn right around and kill it XXX */
		iax_reliable_xmit(&f);
		destroy_session(session);
		break;
	case IAX_EVENT_BUSY:
		fh->type = AST_FRAME_CONTROL;
		fh->seqno = htons(session->oseqno++);
		fh->csub = AST_CONTROL_BUSY;
		/* XXX Not really reliable since we turn right around and kill it XXX */
		iax_reliable_xmit(&f);
		destroy_session(session);
		break;
	case IAX_EVENT_ACCEPT:
		fh->type = AST_FRAME_IAX;
		fh->seqno = htons(session->oseqno++);
		fh->csub = IAX_COMMAND_ACCEPT;
		f.datalen += snprintf((char *)(fh->data), left, "formats=%d;", sformats);
		f.datalen++;
		iax_reliable_xmit(&f);
		break;
	case IAX_EVENT_LAGRQ:
		fh->type = AST_FRAME_IAX;
		fh->seqno = htons(session->oseqno++);
		fh->csub = IAX_COMMAND_LAGRQ;
		iax_reliable_xmit(&f);
		break;
	case IAX_EVENT_ANSWER:
		fh->type = AST_FRAME_CONTROL;
		fh->seqno = htons(session->oseqno++);
		fh->csub = AST_CONTROL_ANSWER;
		iax_reliable_xmit(&f);
		break;
	case IAX_EVENT_PONG:
		fh->type = AST_FRAME_IAX;
		fh->csub = IAX_COMMAND_PONG;
		fh->ts = htonl(event->event.ping.ts);
		iax_reliable_xmit(&f);
		break;
	case IAX_EVENT_URL:
		fh->type = AST_FRAME_HTML;
		fh->seqno = htons(session->oseqno++);
		if (event->event.url.link)
			fh->csub = AST_HTML_LINKURL;
		else
			fh->csub = AST_HTML_URL;
		if (event->event.url.url) {
			f.datalen += strlen(event->event.url.url) + 1;
			strcpy(fh->data, event->event.url.url);
		}
		iax_reliable_xmit(&f);
		break;
	case IAX_EVENT_TEXT:
		fh->type = AST_FRAME_TEXT;
		fh->seqno = htons(session->oseqno++);
		fh->csub = AST_FRAME_TEXT;
		f.datalen += strlen(event->event.text.text) + 1;
		strcpy(fh->data, event->event.text.text);

		iax_reliable_xmit(&f);
		break;

	case IAX_EVENT_UNLINK:
		fh->type = AST_FRAME_HTML;
		fh->seqno = htons(session->oseqno++);
		fh->csub = AST_HTML_UNLINK;
		iax_reliable_xmit(&f);
		break;
	case IAX_EVENT_LINKREJECT:
		fh->type = AST_FRAME_HTML;
		fh->seqno = htons(session->oseqno++);
		fh->csub = AST_HTML_LINKREJECT;
		iax_reliable_xmit(&f);
		break;
	case IAX_EVENT_LDCOMPLETE:
		fh->type = AST_FRAME_HTML;
		fh->seqno = htons(session->oseqno++);
		fh->csub = AST_HTML_LDCOMPLETE;
		iax_reliable_xmit(&f);
		break;
	case IAX_EVENT_VOICE:
		ts = ntohl(fh->ts);
		if (event->event.voice.datalen > left) {
			strcpy(iax_errstr, "Voice frame too large\n");
		}
		/* Don't do anything if we're quelching audio */
		if (session->quelch)
			break;
		/* If the voice format is the same, and the top of our 
		   timestamp is the same, then we stick with a mini-frame, otherwise
		   we send a large frame */
		if ((event->event.voice.format == session->svoiceformat) &&
		    ((session->lastvoicets & 0xFFFF0000) == (ts & 0xFFFF0000))) {
			/* We can send a mini-frame since we're using the same
			   voice format and don't need a timestamp update.  */
			f.datalen += event->event.voice.datalen;
			f.datalen -= sizeof(struct iax_full_hdr) - sizeof(struct iax_mini_hdr);
			memcpy(mh->data, event->event.voice.data, event->event.voice.datalen);
			mh->ts = htons((short)(ts & 0x0000FFFF));
			mh->callno = htons((short)session->callno);
			session->lastvoicets = ts;
			iax_xmit_frame(&f);
		} else {
			/* Send a full frame for our voice frame */
			fh->type = AST_FRAME_VOICE;
			fh->csub = compress_subclass(event->event.voice.format);
			session->svoiceformat = event->event.voice.format;
			fh->seqno = htons((short) session->oseqno++);
			memcpy(fh->data, event->event.voice.data, event->event.voice.datalen);
			f.datalen += event->event.voice.datalen;
			session->lastvoicets = ts;
			iax_reliable_xmit(&f);
		}
		break;
	case IAX_EVENT_IMAGE:
		fh->type = AST_FRAME_IMAGE;
		fh->csub = compress_subclass(event->event.image.format);
		fh->seqno = htons((short) session->oseqno++);
		memcpy(fh->data, event->event.image.data, event->event.image.datalen);
		f.datalen += event->event.image.datalen;
		iax_reliable_xmit(&f);
		break;
	case IAX_EVENT_DIAL:
		fh->type = AST_FRAME_IAX;
		fh->seqno = htons(session->oseqno++);
		fh->csub = IAX_COMMAND_DIAL;
		MYSNPRINTF "%s", event->event.dial.number);
		f.datalen += strlen(requeststr);
		iax_reliable_xmit(&f);
		break;
	case IAX_EVENT_DPREQ:
		fh->type = AST_FRAME_IAX;
		fh->seqno = htons(session->oseqno++);
		fh->csub = IAX_COMMAND_DPREQ;
		MYSNPRINTF "%s", event->event.dpreq.number);
		f.datalen += strlen(requeststr);
		iax_reliable_xmit(&f);
		break;
	case IAX_EVENT_TXREPLY:
		/* Transmit an IAX Transmit request */
		fh->type = AST_FRAME_IAX;
		fh->seqno = htons(0);
		fh->csub = IAX_COMMAND_TXCNT;
		fh->dcallno = htons((short)session->transfercallno);
		f.transferpacket = 1;
		iax_reliable_xmit(&f);
		break;
	case IAX_EVENT_TXREJECT:
		/* Reject the IAX transfer -- the peer couldn't see us or we couldn't see them */
		fh->type = AST_FRAME_IAX;
		fh->seqno = htons(session->oseqno++);
		fh->csub = IAX_COMMAND_TXREJ;
		iax_reliable_xmit(&f);
		break;
	case IAX_EVENT_TXACCEPT:
		/* Accept a connect request */
		fh->type = AST_FRAME_IAX;
		fh->seqno = htons(0);
		fh->csub = IAX_COMMAND_TXACC;
		fh->dcallno = htons((short)session->transfercallno);
		f.transferpacket = 1;
		f.retries = -1;
		iax_xmit_frame(&f);
		break;
	case IAX_EVENT_TXREADY:
		/* We've been accepted on the transfer.  Notify the gateway that we're ready */
		fh->type = AST_FRAME_IAX;
		fh->seqno = htons(session->oseqno++);
		fh->csub = IAX_COMMAND_TXREADY;
		iax_reliable_xmit(&f);
		break;
	case IAX_EVENT_QUELCH:
		fh->type = AST_FRAME_IAX;
		fh->seqno = htons(session->oseqno++);
		fh->csub = IAX_COMMAND_QUELCH;
		iax_reliable_xmit(&f);
		break;
	case IAX_EVENT_UNQUELCH:
		fh->type = AST_FRAME_IAX;
		fh->seqno = htons(session->oseqno++);
		fh->csub = IAX_COMMAND_UNQUELCH;
		iax_reliable_xmit(&f);
		break;
	default:
		DEBU(G "Don't know how to send a %d event\n", event->etype);
		IAXERROR "Unknown event type.\n");
	}
	return 0;
}

static void destroy_session(struct iax_session *session)
{
	struct iax_session *cur, *prev=NULL;
	struct iax_sched *curs, *prevs=NULL, *nexts=NULL;
	int    loop_cnt=0;
	curs = schedq;
	while(curs) {
		nexts = curs->next;
		if (curs->frame && curs->frame->session == session) {
			/* Just mark these frames as if they've been sent */
			curs->frame->retries = -1;
		} else if (curs->event && curs->event->session == session) {
			if (prevs)
				prevs->next = nexts;
			else
				schedq = nexts;
			if (curs->event)
				iax_event_free(curs->event);
			free(curs);
		} else {
			prevs = curs;
		}
		curs = nexts;
		loop_cnt++;
	}
		
	cur = sessions;
	while(cur) {
		if (cur == session) {
			if (prev)
				prev->next = session->next;
			else
				sessions = session->next;
			free(session);
			return;
		}
		prev = cur;
		cur = cur->next;
	}
}

static struct iax_event *handle_event(struct iax_event *event)
{
	/* We have a candidate event to be delievered.  Be sure
	   the session still exists. */
	if (event) {
		if (iax_session_valid(event->session)) {
			/* Lag requests are never actually sent to the client, but
			   other than that are handled as normal packets */
			switch(event->etype) {
			case IAX_EVENT_REGREP:
			case IAX_EVENT_REJECT:
			case IAX_EVENT_HANGUP:
				/* Destroy this session -- it's no longer valid */
				destroy_session(event->session);
				return event;
			case IAX_EVENT_LAGRQ:
				event->etype = IAX_EVENT_LAGRP;
				iax_do_event(event->session, event);
				iax_event_free(event);
				break;
			case IAX_EVENT_PING:
				event->etype = IAX_EVENT_PONG;
				iax_do_event(event->session, event);
				iax_event_free(event);
				break;
			default:
				return event;
			}
		}
	}
	return NULL;
}

int iax_send_dtmf(struct iax_session *session, char digit)
{
	/* Send a DTMF digit */
	struct iax_event e;
	e.etype = IAX_EVENT_DTMF;
	e.event.dtmf.digit = digit;
	return iax_do_event(session, &e);
}

int iax_send_voice(struct iax_session *session, int format, char *data, int datalen)
{
	/* Send a (possibly compressed) voice frame */
	struct iax_event e;
	e.etype = IAX_EVENT_VOICE;
	e.event.voice.format = format;
	e.event.voice.data = data;
	e.event.voice.datalen = datalen;
	return iax_do_event(session, &e);
}

int iax_send_image(struct iax_session *session, int format, char *data, int datalen)
{
	/* Send an image frame */
	struct iax_event e;
	e.etype = IAX_EVENT_IMAGE;
	e.event.image.format = format;
	e.event.image.data = data;
	e.event.image.datalen = datalen;
	return iax_do_event(session, &e);
}

int iax_register(struct iax_session *session, char *server, char *peer, char *secret, int refresh)
{
	/* Send a registration request */
	struct iax_event e;
	char *tmp = strdup(server);
	int res;
	if (!tmp)
		return -1;
	e.etype = IAX_EVENT_REGREQ;
	e.event.regrequest.server = tmp;
	if (strchr(e.event.regrequest.server, ':')) {
		strtok(e.event.regrequest.server, ":");
		e.event.regrequest.portno = atoi(strtok(NULL, ":"));
	} else
		e.event.regrequest.portno = IAX_DEFAULT_PORTNO;
	e.event.regrequest.peer = peer;
	e.event.regrequest.secret = secret;
	e.event.regrequest.refresh = refresh;
	res = iax_do_event(session, &e);
	free(tmp);
	return res;
}

int iax_reject(struct iax_session *session, char *reason)
{
	struct iax_event e;
	e.etype = IAX_EVENT_REJECT;
	e.event.reject.reason = reason;
	return iax_do_event(session, &e);
}

int iax_hangup(struct iax_session *session, char *byemsg)
{
	struct iax_event e;
	e.etype = IAX_EVENT_HANGUP;
	e.event.hangup.byemsg = byemsg;
	return iax_do_event(session, &e);
}

int iax_sendurl(struct iax_session *session, char *url)
{
	struct iax_event e;
	e.etype = IAX_EVENT_URL;
	e.event.url.url = url;
	return iax_do_event(session, &e);
}

int iax_ring_announce(struct iax_session *session)
{
	struct iax_event e;
	e.etype = IAX_EVENT_RINGA;
	return iax_do_event(session, &e);
}

int iax_lag_request(struct iax_session *session)
{
	struct iax_event e;
	e.etype = IAX_EVENT_LAGRQ;
	return iax_do_event(session, &e);
}

int iax_busy(struct iax_session *session)
{
	struct iax_event e;
	e.etype = IAX_EVENT_BUSY;
	return iax_do_event(session, &e);
}

int iax_accept(struct iax_session *session)
{
	struct iax_event e;
	e.etype = IAX_EVENT_ACCEPT;
	return iax_do_event(session, &e);
}

int iax_answer(struct iax_session *session)
{
	struct iax_event e;
	e.etype = IAX_EVENT_ANSWER;
	return iax_do_event(session, &e);
}

int iax_load_complete(struct iax_session *session)
{
	struct iax_event e;
	e.etype = IAX_EVENT_LDCOMPLETE;
	return iax_do_event(session, &e);
}

int iax_send_url(struct iax_session *session, char *url, int link)
{
	struct iax_event e;
	e.etype = IAX_EVENT_URL;
	e.event.url.link = link;
	e.event.url.url = url;
	return iax_do_event(session, &e);
}

int iax_send_text(struct iax_session *session, char *text)
{
	struct iax_event e;
	e.etype = IAX_EVENT_TEXT;
	snprintf(e.event.text.text, sizeof(e.event.text.text), "%s", text);
	return iax_do_event(session, &e);
}

int iax_send_unlink(struct iax_session *session)
{
	struct iax_event e;
	e.etype = IAX_EVENT_UNLINK;
	return iax_do_event(session, &e);
}

int iax_send_link_reject(struct iax_session *session)
{
	struct iax_event e;
	e.etype = IAX_EVENT_LINKREJECT;
	return iax_do_event(session, &e);
}


int iax_auth_reply(struct iax_session *session, char *password, char *challenge, int methods)
{
	struct iax_event e;
	char reply[16];
	struct MD5Context md5;
	char realreply[256];
	e.etype = IAX_EVENT_AUTHRP;
	if ((methods & IAX_AUTHMETHOD_MD5) && challenge) {
		e.event.authreply.authmethod = IAX_AUTHMETHOD_MD5;
		MD5Init(&md5);
		MD5Update(&md5, (const unsigned char *) challenge, strlen(challenge));
		MD5Update(&md5, (const unsigned char *) password, strlen(password));
		MD5Final((unsigned char *) reply, &md5);
		bzero(realreply, sizeof(realreply));
		convert_reply(realreply, (unsigned char *) reply);
		e.event.authreply.reply = realreply;
	} else {
		e.event.authreply.authmethod = IAX_AUTHMETHOD_PLAINTEXT;
		e.event.authreply.reply = password;
	}
	return iax_do_event(session, &e);
}

void iax_set_formats(int fmt)
{
	sformats = fmt;
}

int iax_dial(struct iax_session *session, char *number)
{
	struct iax_event e;
	e.etype = IAX_EVENT_DIAL;
	e.event.dial.number = number;
	return iax_do_event(session, &e);
}

int iax_quelch(struct iax_session *session)
{
	struct iax_event e;
	e.etype = IAX_EVENT_QUELCH;
	return iax_do_event(session, &e);
}

int iax_unquelch(struct iax_session *session)
{
	struct iax_event e;
	e.etype = IAX_EVENT_UNQUELCH;
	return iax_do_event(session, &e);
}

int iax_dialplan_request(struct iax_session *session, char *number)
{
	struct iax_event e;
	e.etype = IAX_EVENT_DPREQ;
	e.event.dpreq.number = number;
	return iax_do_event(session, &e);
}

int iax_call(struct iax_session *session, char *callerid, char *ich, char *lang, int wait)
{
	struct iax_event e;
	char *tmp = ich ? strdup(ich) : NULL;
	char *part1, *part2;
	int res;
	/* We start by parsing up the temporary variable which is of the form of:
	   [user@]peer[:portno][/exten[@context]] */
	if (!tmp) {
		IAXERROR "Invalid IAX Call Handle\n");
		DEBU(G "Invalid IAX Call Handle\n");
		return -1;
	}
	
	e.event.connect.callerid = callerid;
	e.event.connect.formats = sformats;
	e.event.connect.version = IAX_PROTO_VERSION;
	e.event.connect.language = lang;
	
	e.etype = IAX_EVENT_CONNECT;
	/* Part 1 is [user[:password]@]peer[:port] */
	part1 = strtok(tmp, "/");

	/* Part 2 is exten[@context] if it is anything all */
	part2 = strtok(NULL, "/");
	
	if (strchr(part1, '@')) {
		e.event.connect.username = strtok(part1, "@");
		e.event.connect.hostname = strtok(NULL, "@");
	} else {
		e.event.connect.username = NULL;
		e.event.connect.hostname = part1;
	}
	
	if (e.event.connect.username && strchr(e.event.connect.username, ':')) {
		e.event.connect.username = strtok(e.event.connect.username, ":");
		e.event.connect.secret = strtok(NULL, ":");
	}
	
	if (strchr(e.event.connect.hostname, ':')) {
		strtok(e.event.connect.hostname, ":");
		e.event.connect.portno = atoi(strtok(NULL, ":"));
	} else {
		e.event.connect.portno = IAX_DEFAULT_PORTNO;
	}
	if (part2) {
		e.event.connect.exten = strtok(part2, "@");
		e.event.connect.dnid = e.event.connect.exten;
		e.event.connect.context = strtok(NULL, "@");
	} else {
		e.event.connect.exten = NULL;
		e.event.connect.dnid = NULL;
		e.event.connect.context = NULL;
	}
	res = iax_do_event(session, &e);
	free(tmp);
	if (res < 0)
		return res;
	if (wait) {
		DEBU(G "Waiting not yet implemented\n");
		return -1;
	}
	return res;
}

static int calc_rxstamp(struct iax_session *session)
{
	struct timeval tv;
	int ms;

	if (!session->rxcore.tv_sec && !session->rxcore.tv_usec) {
		gettimeofday(&session->rxcore, NULL);
	}	
	gettimeofday(&tv, NULL);

	ms = (tv.tv_sec - session->rxcore.tv_sec) * 1000 +
		 (tv.tv_usec - session->rxcore.tv_usec) / 1000;
		return ms;
}

static int match(struct sockaddr_in *sin, short callno, short dcallno, struct iax_session *cur)
{
	if ((cur->peeraddr.sin_addr.s_addr == sin->sin_addr.s_addr) &&
		(cur->peeraddr.sin_port == sin->sin_port)) {
		/* This is the main host */
		if ((cur->peercallno == callno) || 
			((dcallno == cur->callno) && (cur->peercallno) == -1)) {
			/* That's us.  Be sure we keep track of the peer call number */
			cur->peercallno = callno;
			return 1;
		}
	}
	if ((cur->transfer.sin_addr.s_addr == sin->sin_addr.s_addr) &&
	    (cur->transfer.sin_port == sin->sin_port) && (cur->transferring)) {
		/* We're transferring */
		if (dcallno == cur->callno)
			return 1;
	}
	return 0;
}

static struct iax_session *iax_find_session(struct sockaddr_in *sin, 
											short callno, 
											short dcallno,
											int makenew)
{
	struct iax_session *cur = sessions;
	while(cur) {
		if (match(sin, callno, dcallno, cur))
			return cur;
		cur = cur->next;
	}
	if (makenew && (dcallno == -1)) {
		cur = iax_session_new();
		cur->peercallno = callno;
		cur->peeraddr.sin_addr.s_addr = sin->sin_addr.s_addr;
		cur->peeraddr.sin_port = sin->sin_port;
		cur->peeraddr.sin_family = AF_INET;
		DEBU(G "Making new session, peer callno %d, our callno %d\n", callno, cur->callno);
	} else {
		DEBU(G "No session, peer = %d, us = %d\n", callno, dcallno);
	}
	return cur;	
}

#ifdef EXTREME_DEBUG
static int display_time(int ms)
{
	static int oldms = -1;
	if (oldms < 0) {
		DEBU(G "First measure\n");
		oldms = ms;
		return 0;
	}
	DEBU(G "Time from last frame is %d ms\n", ms - oldms);
	oldms = ms;
	return 0;
}
#endif

#define FUDGE 1

static struct iax_event *schedule_delivery(struct iax_event *e, unsigned int ts)
{
	/* 
	 * This is the core of the IAX jitterbuffer delivery mechanism: 
	 * Dynamically adjust the jitterbuffer and decide how long to wait
	 * before delivering the packet.
	 */
	int ms, x;
	int drops[MEMORY_SIZE];
	int min, max=0, maxone=0, y, z, match;


#ifdef EXTREME_DEBUG	
	DEBU(G "[%p] We are at %d, packet is for %d\n", e->session, calc_rxstamp(e->session), ts);
#endif
	
#ifdef VOICE_SMOOTHING
	if (e->etype == IAX_EVENT_VOICE) {
		/* Smooth voices if we know enough about the format */
		switch(e->event.voice.format) {
		case AST_FORMAT_GSM:
			/* GSM frames are 20 ms long, although there could be periods of 
			   silence.  If the time is < 50 ms, assume it ought to be 20 ms */
			if (ts - e->session->lastts < 50)  
				ts = e->session->lastts + 20;
#ifdef EXTREME_DEBUG
			display_time(ts);
#endif
			break;
		default:
			/* Can't do anything */
		}
		e->session->lastts = ts;
	}
#endif
	
	/* How many ms from now should this packet be delivered? (remember
	   this can be a negative number, too */
	ms = calc_rxstamp(e->session) - ts;
	if (ms > 32768) {
		/* What likely happened here is that our counter has circled but we haven't
		   gotten the update from the main packet.  We'll just pretend that we did, and
		   update the timestamp appropriately. */
		ms -= 65536;
	}
	if (ms < -32768) {
		/* We got this packet out of order.  Lets add 65536 to it to bring it into our new
		   time frame */
		ms += 65536;
	}

#if 0	
	printf("rxstamp is %d, timestamp is %d, ms is %d\n", calc_rxstamp(e->session), ts, ms);
#endif
	/* Rotate history queue.  Leading 0's are irrelevant. */
	for (x=0; x < MEMORY_SIZE - 1; x++) 
		e->session->history[x] = e->session->history[x+1];
	
	/* Add new entry for this time */
	e->session->history[x] = ms;
	
	/* We have to find the maximum and minimum time delay we've had to deliver. */
	min = e->session->history[0];
	for (z=0;z < iax_dropcount + 1; z++) {
		/* We drop the top iax_dropcount entries.  iax_dropcount represents
		   a tradeoff between quality of voice and latency.  3% drop seems to
		   be unnoticable to the client and can significantly improve latency.  
		   We add one more to our droplist, but that's the one we actually use, 
		   and don't drop.  */
		max = -99999999;
		for (x=0;x<MEMORY_SIZE;x++) {
			if (max < e->session->history[x]) {
				/* New candidate value.  Make sure we haven't dropped it. */
				match=0;
				for(y=0;!match && (y<z); y++) 
					match |= (drops[y] == x);
				/* If there is no match, this is our new maximum */
				if (!match) {
					max = e->session->history[x];
					maxone = x;
				}
			}
			if (!z) {
				/* First pass, calcualte our minimum, too */
				if (min > e->session->history[x])
					min = e->session->history[x];
			}
		}
		drops[z] = maxone;
	}
	/* Again, just for reference.  The "jitter buffer" is the max.  The difference
	   is the perceived jitter correction. */
	e->session->jitter = max - min;
	
	/* If the jitter buffer is substantially too large, shrink it, slowly enough
	   that the client won't notice ;-) . */
	if (max < e->session->jitterbuffer - max_extra_jitterbuffer) {
#ifdef EXTREME_DEBUG
		DEBU(G "Shrinking jitterbuffer (target = %d, current = %d...\n", max, e->session->jitterbuffer);
#endif
		e->session->jitterbuffer -= 2;
	}
		
	/* Keep the jitter buffer from becoming unreasonably large */
	if (max > min + max_jitterbuffer) {
		DEBU(G "Constraining jitter buffer (min = %d, max = %d)...\n", min, max);
		max = min + max_jitterbuffer;
	}
	
	/* If the jitter buffer is too small, we immediately grow our buffer to
	   accomodate */
	if (max > e->session->jitterbuffer)
		e->session->jitterbuffer = max;
	
	/* Start with our jitter buffer delay, and subtract the lateness (or earliness).
	   Remember these times are all relative to the first packet, so their absolute
	   values are really irrelevant. */
	ms = e->session->jitterbuffer - ms - IAX_SCHEDULE_FUZZ;
	
	/* If the jitterbuffer is disabled, always deliver immediately */
	if (!iax_use_jitterbuffer)
		ms = 0;
	
	if (ms < 1) {
#ifdef EXTREME_DEBUG
		DEBU(G "Calculated delay is only %d\n", ms);
#endif
		if ((ms > -4) || (e->etype != IAX_EVENT_VOICE)) {
			/* Return the event immediately if it's it's less than 3 milliseconds
			   too late, or if it's not voice (believe me, you don't want to
			   just drop a hangup frame because it's late, or a ping, or some such.
			   That kinda ruins retransmissions too ;-) */
			return e;
		}
		DEBU(G "(not so) Silently dropping a packet (ms = %d)\n", ms);
		/* Silently discard this as if it were to be delivered */
		free(e->event.voice.data);
		free(e);
		return NULL;
	}
	/* We need this to be delivered in the future, so we use our scheduler */
	iax_sched_event(e, NULL, ms);
#ifdef EXTREME_DEBUG
	DEBU(G "Delivering packet in %d ms\n", ms);
#endif
	return NULL;
	
}

static int uncompress_subclass(unsigned char csub)
{
	/* If the SC_LOG flag is set, return 2^csub otherwise csub */
	if (csub & IAX_FLAG_SC_LOG)
		return 1 << (csub & ~IAX_FLAG_SC_LOG & IAX_MAX_SHIFT);
	else
		return csub;
}

static
#ifndef	WIN32
inline
#endif
char *extract(char *src, char *string)
{
	/* Extract and duplicate what we need from a string */
	char *s, *t;
	s = strstr(src, string);
	if (s) {
		s += strlen(string);
		s = strdup(s);
		/* End at ; */
		t = strchr(s, ';');
		if (t) {
			*t = '\0';
		}
	}
	return s;
		
}

static void send_ack(struct iax_session *session, struct iax_full_hdr *fhi)
{
	short tco;
	struct iax_frame f;
	struct iax_full_hdr h;
	struct iax_full_hdr *fh = &h;
	/* To ack, we use the same sequence number and
	   timestamp, just swapping the source and destination
	    */
	memcpy(fh, fhi, sizeof(h));
	tco = ntohs(fh->callno) & ~IAX_FLAG_FULL;
#ifdef EXTREME_DEBUG
	DEBU(G "Acking peer's callno %d (our callno %d) seqno %d\n", tco, (int)session->callno, ntohs(fh->seqno));
#endif
	fh->dcallno = htons(tco);
	fh->callno = htons((short) (session->callno | IAX_FLAG_FULL));
	fh->type = AST_FRAME_IAX;
	fh->csub = IAX_COMMAND_ACK;
	f.retries = -1;
	f.session = session;
	f.data = fh;
	f.datalen = sizeof(struct iax_full_hdr);
	f.transferpacket = 0;
	iax_xmit_frame(&f);
}

static struct iax_event *iax_header_to_event(struct iax_session *session,
											 struct iax_full_hdr *fh,
											 int datalen)
{
	struct iax_event *e;
	struct iax_sched *sch;
	unsigned int ts;
	int subclass = uncompress_subclass(fh->csub);
	char *text = fh->data;
	char *s;
	char *methods;
	int nowts;
	ts = ntohl(fh->ts);
	session->last_ts = ts;
	e = (struct iax_event *)malloc(sizeof(struct iax_event));

#ifdef DEBUG_SUPPORT
	showframe(NULL, fh, 1);
#endif

	/* Get things going with it, timestamp wise, if we
	   haven't already. */

	if ((fh->type != AST_FRAME_IAX) ||
	    ((subclass != IAX_COMMAND_ACK) && 
		 (subclass != IAX_COMMAND_INVAL) &&
		 (subclass != IAX_COMMAND_REJECT) &&
		 (subclass != IAX_COMMAND_TXCNT) &&
		 (subclass != IAX_COMMAND_TXACC)))
			send_ack(session, fh);

	/* Null terminate text */
	if (text)
		text[datalen] = '\0';
			
	if (e) {
		memset(e, 0, sizeof(struct iax_event));
		e->session = session;
		switch(fh->type) {
		case AST_FRAME_DTMF:
			e->etype = IAX_EVENT_DTMF;
			e->event.dtmf.digit = subclass;
			return schedule_delivery(e, ts);
		case AST_FRAME_VOICE:
			e->etype = IAX_EVENT_VOICE;
			e->event.voice.format = subclass;
			session->voiceformat = subclass;
			if (datalen) {
				e->event.voice.data = (char *)malloc(datalen);
				e->event.voice.datalen = datalen;
				if (e->event.voice.data) {
					memcpy(e->event.voice.data, fh->data, datalen);
				} else {
					free(e);
					e = NULL;
					DEBU(G "Out of memory\n");
					return e;
				}
			} else {
				/* Empty voice frame?  Maybe it could happen... */
				e->event.voice.data = NULL;
				e->event.voice.datalen = 0;
			}
			return schedule_delivery(e, ts);
		case AST_FRAME_IAX:
			switch(subclass) {
			case IAX_COMMAND_NEW:
				/* This is a new, incoming call */
				e->etype = IAX_EVENT_CONNECT;

				/* Now we search for each each component of
				   the call, if present. */

				e->event.connect.callerid = extract(text, "callerid=");
				e->event.connect.dnid = extract(text, "dnid=");
				e->event.connect.exten = extract(text, "exten=");
				e->event.connect.context = extract(text, "context=");
				e->event.connect.username = extract(text, "username=");
				e->event.connect.language = extract(text, "language=");
				s = extract(text, "formats=");
				if (s) 
					e->event.connect.formats = atoi(s);
				else
					e->event.connect.formats = 0;
				s = extract(text, "version=");
				if (s)
					e->event.connect.version = atoi(s);
				else
					e->event.connect.version = 0;
				e->event.connect.hostname = strdup(inet_ntoa(e->session->peeraddr.sin_addr));
				return schedule_delivery(e, ts);
			case IAX_COMMAND_AUTHREQ:
				/* This is a new, incoming call */
				e->etype = IAX_EVENT_AUTHRQ;

				/* Now we search for each each component of
				   the call, if present. */

				e->event.authrequest.username = extract(text, "username=");
				methods = extract(text, "methods=");
				e->event.authrequest.authmethods = 0;
				if (methods) {
					if (strstr(methods, "md5"))
						e->event.authrequest.authmethods |= IAX_AUTHMETHOD_MD5;
					if (strstr(methods, "plaintext"))
						e->event.authrequest.authmethods |= IAX_AUTHMETHOD_PLAINTEXT;
					free(methods);
				}
				e->event.authrequest.challenge = extract(text, "challenge=");
				return schedule_delivery(e, ts);
			case IAX_COMMAND_HANGUP:
				e->etype = IAX_EVENT_HANGUP;
				if (datalen)
					e->event.hangup.byemsg = strdup(text);
				else
					e->event.hangup.byemsg = NULL;
				return schedule_delivery(e, ts);
			case IAX_COMMAND_INVAL:
				e->etype = IAX_EVENT_HANGUP;
				e->event.hangup.byemsg = NULL;
				return schedule_delivery(e, ts);
			case IAX_COMMAND_REJECT:
				e->etype = IAX_EVENT_REJECT;
				e->event.reject.reason = (text ? strdup(text) : NULL);
				return schedule_delivery(e, ts);
			case IAX_COMMAND_ACK:
				if (ntohs(fh->seqno) <= session->iseqno) {
					/* We just need to go through and acknowledge the matching
					   packet(s) that are planned to be retransmitted */
					sch = schedq;
					while(sch) {
						if (sch->frame && (sch->frame->session == session) &&
							(((struct iax_full_hdr *)(sch->frame->data))->seqno ==
								fh->seqno))
								sch->frame->retries = -1;
						sch = sch->next;
					}
					if (ntohs(fh->seqno) == session->iseqno) 
						session->iseqno++;
				} else
					DEBU(G "Received ACK for %d, expecting %d\n", ntohs(fh->seqno), session->iseqno);
				free(e);
				return NULL;
				break;
			case IAX_COMMAND_LAGRQ:
				/* Pass this along for later handling */
				e->etype = IAX_EVENT_LAGRQ;
				e->event.lagrq.ts = ts;
				return schedule_delivery(e, ts);
			case IAX_COMMAND_PING:
				/* Just immediately reply */
				e->etype = IAX_EVENT_PING;
				e->event.ping.ts = ts;
				e->event.ping.seqno = ntohs(fh->seqno);
				return schedule_delivery(e, ts);
			case IAX_COMMAND_ACCEPT:
				e->etype = IAX_EVENT_ACCEPT;
				return schedule_delivery(e, ts);
			case IAX_COMMAND_REGACK:
				e->etype = IAX_EVENT_REGREP;
				e->event.regreply.status = IAX_REG_SUCCESS;
				e->event.regreply.ourip = extract(text, "yourip=");
				s = extract(text, "yourport=");
				e->event.regreply.ourport = s ? atoi(s) : 0;
				if (s) free(s);
				s = extract(text, "refresh=");
				e->event.regreply.refresh = s ? atoi(s) : 0;
				if (s) free(s);
				s = extract(text, "callerid=");
				e->event.regreply.callerid = s;
				return schedule_delivery(e, ts);
			case IAX_COMMAND_REGAUTH:
				/* Ooh, don't bother telling the user, just do it */
				e->etype = IAX_EVENT_REREQUEST;
				s = extract(text, "methods=");
				if (!s) {
					DEBU(G "No methods specified?\n");
					free(e);
					return NULL;
				}
				strncpy(session->methods, s, sizeof(session->methods)-1);
				s = extract(text, "challenge=");
				if (s) 
					strncpy(session->challenge, s, sizeof(session->challenge)-1);
				else
					strcpy(session->challenge, "");
				iax_do_event(session, e);
				free(e);
				return NULL;
			case IAX_COMMAND_REGREJ:
				e->etype = IAX_EVENT_REGREP;
				e->event.regreply.status = IAX_REG_REJECT;
				e->event.regreply.ourip = NULL;
				e->event.regreply.ourport = 0;
				s = extract(text, "refresh=");
				e->event.regreply.refresh = s ? atoi(s) : 0;
				return schedule_delivery(e, ts);
			case IAX_COMMAND_LAGRP:
				e->etype = IAX_EVENT_LAGRP;
				nowts = calc_timestamp(session, 0);
				e->event.lag.lag = nowts - ts;
				e->event.lag.jitter = session->jitter;
				/* Can't call schedule_delivery since timestamp is non-normal */
				return e;
			case IAX_COMMAND_TXREQ:
				/* Received transfer request, start the process */
				s = extract(text, "remip=");
				if (s) {
					if (inet_aton(s, &session->transfer.sin_addr)) {
						s = extract(text, "remport=");
						if (s) {
							session->transfer.sin_port = htons(atoi(s));
							free(s);
							s = extract(text, "remcall=");
							if (s) {
								session->transfer.sin_family = AF_INET;
								session->transfercallno = atoi(s);
								free(s);
								session->transferring = TRANSFER_BEGIN;
								e->etype = IAX_EVENT_TXREPLY;
								iax_do_event(session, e);
							}
						}
					}
				}
				free(e);
				return NULL;
			case IAX_COMMAND_DPREP:
				/* Received dialplan reply */
				printf("Got dialplan reply: %s\n", text);
				e->etype = IAX_EVENT_DPREP;
				s = extract(text, "number=");
				if (s)
					e->event.dprep.number = s;
				e->event.dprep.canexist = 0;
				e->event.dprep.exists = 0;
				e->event.dprep.nonexistant = 0;
				s = extract(text, "status=");
				if (s) {
					if (!strcmp(s, "canexist"))
						e->event.dprep.canexist = 1;
					else if (!strcmp(s, "exists"))
						e->event.dprep.exists = 1;
					else if (!strcmp(s, "nonexistant"))
						e->event.dprep.nonexistant = 1;
					else
						fprintf(stderr, "Unknown status '%s'\n", s);
					free(s);
				}
				e->event.dprep.ignorepat = 0;
				s = extract(text, "ignorepat=");
				if (s) {
					if (!strcmp(s, "yes"))
						e->event.dprep.ignorepat = 1;
					free(s);
				}
				s = extract(text, "expirey=");
				if (s) {
					e->event.dprep.expirey = atoi(s);
					if (e->event.dprep.expirey < 0)
						e->event.dprep.expirey = 0;
					free(s);
				} else
					e->event.dprep.expirey = 0;
				/* Return immediately, makes no sense to schedule */
				return e;
			case IAX_COMMAND_TXCNT:
				/* Received a transfer connect.  Accept it if we're transferring */
				e->etype = IAX_EVENT_TXACCEPT;
				if (session->transferring) 
					iax_do_event(session, e);
				free(e);
				return NULL;
			case IAX_COMMAND_TXACC:
				e->etype = IAX_EVENT_TXREADY;
				if (session->transferring) {
					/* Cancel any more connect requests */
					sch = schedq;
					while(sch) {
						if (sch->frame && sch->frame->transferpacket)
								sch->frame->retries = -1;
						sch = sch->next;
					}
					session->transferring = TRANSFER_READY;
					iax_do_event(session, e);
				}
				free(e);
				return NULL;
			case IAX_COMMAND_TXREL:
				printf("Release: text is %s\n", text);
				/* Release the transfer */
				s = extract(text, "peercallno=");
				if (s) 
					session->peercallno = atoi(s);
				/* Change from transfer to session now */
				memcpy(&session->peeraddr, &session->transfer, sizeof(session->peeraddr));
				memset(&session->transfer, 0, sizeof(session->transfer));
				session->transferring = TRANSFER_NONE;
				/* Force retransmission of a real voice packet, and reset all timing */
				session->svoiceformat = -1;
				session->voiceformat = 0;
				memset(&session->rxcore, 0, sizeof(session->rxcore));
				memset(&session->offset, 0, sizeof(session->offset));
				memset(&session->history, 0, sizeof(session->history));
				session->jitterbuffer = 0;
				session->jitter = 0;
				session->lag = 0;
				/* Reset sequence numbers */
				session->oseqno = 0;
				session->iseqno = 0;
				session->lastsent = 0;
				session->last_ts = 0;
				session->lastvoicets = 0;
				session->pingtime = 30;
				e->etype = IAX_EVENT_TRANSFER;
				e->event.transfer.newip = strdup(inet_ntoa(session->peeraddr.sin_addr));
				e->event.transfer.newport = ntohs(session->peeraddr.sin_port);
				/* We have to dump anything we were going to (re)transmit now that we've been
				   transferred since they're all invalid and for the old host. */
				sch = schedq;
				while(sch) {
					if (sch->frame && (sch->frame->session == session))
								sch->frame->retries = -1;
					sch = sch->next;
				}
				return e;
			case IAX_COMMAND_QUELCH:
				e->etype = IAX_EVENT_QUELCH;
				session->quelch = 1;
				return e;
			case IAX_COMMAND_UNQUELCH:
				e->etype = IAX_EVENT_UNQUELCH;
				session->quelch = 0;
				return e;
			default:
				DEBU(G "Don't know what to do with IAX command %d\n", subclass);
				free(e);
				return NULL;
			}
			break;
		case AST_FRAME_CONTROL:
			switch(subclass) {
			case AST_CONTROL_ANSWER:
				e->etype = IAX_EVENT_ANSWER;
				return schedule_delivery(e, ts);
			case AST_CONTROL_BUSY:
				e->etype = IAX_EVENT_BUSY;
				return schedule_delivery(e, ts);
			case AST_CONTROL_RINGING:
				e->etype = IAX_EVENT_RINGA;
				return schedule_delivery(e, ts);
			default:
				DEBU(G "Don't know what to do with AST control %d\n", subclass);
				free(e);
				return NULL;
			}
			break;
		case AST_FRAME_IMAGE:
			e->etype = IAX_EVENT_IMAGE;
			e->event.image.format = subclass;
			if (datalen) {
				e->event.image.data = (char *)malloc(datalen);
				e->event.image.datalen = datalen;
				if (e->event.image.data) {
					memcpy(e->event.image.data, fh->data, datalen);
				} else {
					free(e);
					e = NULL;
					DEBU(G "Out of memory\n");
					return NULL;
				}
			} else {
				/* Empty image frame?  Maybe it could happen... */
				e->event.image.data = NULL;
				e->event.image.datalen = 0;
			}
			return schedule_delivery(e, ts);

		case AST_FRAME_TEXT:
			e->etype = IAX_EVENT_TEXT;
			strncpy(e->event.text.text, (char *)fh->data, datalen);
			return schedule_delivery(e, ts);

		case AST_FRAME_HTML:
			switch(fh->csub) {
			case AST_HTML_LINKURL:
				e->event.url.link = 1;
				/* Fall through */
			case AST_HTML_URL:
				e->etype = IAX_EVENT_URL;
				if (datalen) {
					e->event.url.url = (char *)malloc(datalen + 1);
					strncpy(e->event.url.url, (char *)fh->data, datalen);
				}
				return schedule_delivery(e, ts);
			case AST_HTML_LDCOMPLETE:
				e->etype = IAX_EVENT_LDCOMPLETE;
				return schedule_delivery(e, ts);
			case AST_HTML_UNLINK:
				e->etype = IAX_EVENT_UNLINK;
				return schedule_delivery(e, ts);
			case AST_HTML_LINKREJECT:
				e->etype = IAX_EVENT_LINKREJECT;
				return schedule_delivery(e, ts);
			default:
				DEBU(G "Don't know how to handle HTML type %d frames\n", fh->csub);
				free(e);
				return NULL;
			}
			break;
		default:
			DEBU(G "Don't know what to do with frame type %d\n", fh->type);
			free(e);
			return NULL;
		}
	} else
		DEBU(G "Out of memory\n");
	return NULL;
}

static struct iax_event *iax_miniheader_to_event(struct iax_session *session,
						struct iax_mini_hdr *mh,
						int datalen)
{
	struct iax_event *e;
	unsigned int ts;
	e = (struct iax_event *)malloc(sizeof(struct iax_event));
	if (e) {
		if (session->voiceformat > 0) {
			e->etype = IAX_EVENT_VOICE;
			e->session = session;
			e->event.voice.format = session->voiceformat;
			if (datalen) {
#ifdef EXTREME_DEBUG
				DEBU(G "%d bytes of voice\n", datalen);
#endif
				e->event.voice.data = (char *)malloc(datalen);
				if (e->event.voice.data) {
					e->event.voice.datalen = datalen;
					memcpy(e->event.voice.data, mh->data, datalen);
				} else {
					free(e);
					e = NULL;
					DEBU(G "Out of memory\n");
					return e;
				}
			} else {
				/* Empty voice frame?  Maybe it could happen... */
				e->event.voice.data = NULL;
				e->event.voice.datalen = 0;
			}
			ts = (session->last_ts & 0xFFFF0000) | ntohs(mh->ts);
			return schedule_delivery(e, ts);
		} else {
			DEBU(G "No last format received on session %d\n", session->callno);
			free(e);
			e = NULL;
		}
	} else
		DEBU(G "Out of memory\n");
	return e;
}

static struct iax_event *iax_net_read(void)
{
	char buf[IAX_MAX_BUF_SIZE];
	int res;
	struct sockaddr_in sin;
	int sinlen;
	struct iax_full_hdr *fh = (struct iax_full_hdr *)buf;
	struct iax_mini_hdr *mh = (struct iax_mini_hdr *)buf;
	struct iax_session *session;
	
	sinlen = sizeof(sin);
	res = recvfrom(netfd, buf, sizeof(buf), 0, (struct sockaddr *) &sin, &sinlen);
	buf[sizeof(buf) - 1] = '\0';
	if (res < 0) {
#ifdef	WIN32
		if (WSAGetLastError() != WSAEWOULDBLOCK) {
			DEBU(G "Error on read: %d\n", WSAGetLastError());
			IAXERROR "Read error on network socket: %s", strerror(errno));
		}
#else
		if (errno != EAGAIN) {
			DEBU(G "Error on read: %s\n", strerror(errno));
			IAXERROR "Read error on network socket: %s", strerror(errno));
		}
#endif
		return NULL;
	}
	if (ntohs(fh->callno) & IAX_FLAG_FULL) {
		/* Full size header */
		if (res < sizeof(struct iax_full_hdr)) {
			DEBU(G "Short header received from %s\n", inet_ntoa(sin.sin_addr));
			IAXERROR "Short header received from %s\n", inet_ntoa(sin.sin_addr));
		}
		/* We have a full header, process appropriately */
		session = iax_find_session(&sin, (short)(ntohs((short)fh->callno) & ~IAX_FLAG_FULL), ntohs((short)fh->dcallno), 1);
		if (session) 
			return iax_header_to_event(session, fh, res - sizeof(struct iax_full_hdr));
		DEBU(G "No session?\n");
		return NULL;
	} else {
		if (res < sizeof(struct iax_mini_hdr)) {
			DEBU(G "Short header received from %s\n", inet_ntoa(sin.sin_addr));
			IAXERROR "Short header received from %s\n", inet_ntoa(sin.sin_addr));
		}
		/* Miniature, voice frame */
		session = iax_find_session(&sin, ntohs(fh->callno), 0, 0);
		if (session)
			return iax_miniheader_to_event(session, mh, res - sizeof(struct iax_mini_hdr));
		DEBU(G "No session?\n");
		return NULL;
	}
}

static struct iax_sched *iax_get_sched(struct timeval tv)
{
	struct iax_sched *cur, *prev=NULL;
	cur = schedq;
	/* Check the event schedule first. */
	while(cur) {
		if ((tv.tv_sec > cur->when.tv_sec) ||
		    ((tv.tv_sec == cur->when.tv_sec) && 
			(tv.tv_usec >= cur->when.tv_usec))) {
				/* Take it out of the event queue */
				if (prev) {
					prev->next = cur->next;
				} else {
					schedq = cur->next;
				}
				return cur;
		}
		cur = cur->next;
	}
	return NULL;
}

struct iax_event *iax_get_event(int blocking)
{
	struct iax_event *event;
	struct iax_frame *frame;
	struct timeval tv;
	struct iax_sched *cur;
	struct iax_event e;
	
	gettimeofday(&tv, NULL);
	
	while((cur = iax_get_sched(tv))) {
		event = cur->event;
		frame = cur->frame;
		if (event) {

			/* See if this is an event we need to handle */
			event = handle_event(event);
			if (event) {
				free(cur);
				return event;
			}
		} else {
			/* It's a frame, transmit it and schedule a retry */
			if (frame->retries < 0) {
				/* It's been acked.  No need to send it.   Destroy the old
				   frame */
				if (frame->data)
					free(frame->data);
				free(frame);
			} else if (frame->retries == 0) {
				if (frame->transferpacket) {
					/* Send a transfer reject since we weren't able to connect */
					e.etype = IAX_EVENT_TXREJECT;
					iax_do_event(frame->session, &e);
					break;
				} else {
					/* We haven't been able to get an ACK on this packet.  We should
					   destroy its session */
					event = (struct iax_event *)malloc(sizeof(struct iax_event));
					if (event) {
						event->etype = IAX_EVENT_TIMEOUT;
						event->session = frame->session;
						free(cur);
						return handle_event(event);
					}
				}
			} else {
				/* Decrement remaining retries */
				frame->retries--;
				/* Multiply next retry time by 4, not above MAX_RETRY_TIME though */
				frame->retrytime *= 4;
				/* Keep under 1000 ms if this is a transfer packet */
				if (!frame->transferpacket) {
					if (frame->retrytime > MAX_RETRY_TIME)
						frame->retrytime = MAX_RETRY_TIME;
				} else if (frame->retrytime > 1000)
					frame->retrytime = 1000;
				iax_xmit_frame(frame);
				/* Schedule another retransmission */
				printf("Scheduling retransmission %d\n", frame->retries);
				iax_sched_event(NULL, frame, frame->retrytime);
			}
		}
		free(cur);
	}

	/* Now look for networking events */
	if (blocking) {
		/* Block until there is data if desired */
		fd_set fds;
		FD_ZERO(&fds);
		FD_SET(netfd, &fds);
		select(netfd + 1, &fds, NULL, NULL, NULL);
	}
	event = iax_net_read();
	
	return handle_event(event);
}

struct sockaddr_in iax_get_peer_addr(struct iax_session *session)
{
	return session->peeraddr;
}

void iax_event_free(struct iax_event *event)
{
	switch(event->etype) {
	case IAX_EVENT_CONNECT:
		if (event->event.connect.callerid)
			free(event->event.connect.callerid);
		if (event->event.connect.dnid)
			free(event->event.connect.dnid);
		if (event->event.connect.context)
			free(event->event.connect.context);
		if (event->event.connect.exten)
			free(event->event.connect.exten);
		if (event->event.connect.username)
			free(event->event.connect.username);
		if (event->event.connect.hostname)
			free(event->event.connect.hostname);
		if (event->event.connect.language)
			free(event->event.connect.language);
		break;
	case IAX_EVENT_HANGUP:
		if (event->event.hangup.byemsg)
			free(event->event.hangup.byemsg);
		break;
	case IAX_EVENT_REJECT:
		if (event->event.reject.reason)
			free(event->event.reject.reason);
		break;
	case IAX_EVENT_VOICE:
		if (event->event.voice.data)
			free(event->event.voice.data);
		break;
	case IAX_EVENT_IMAGE:
		if (event->event.image.data)
			free(event->event.image.data);
		break;
	case IAX_EVENT_URL:
		if (event->event.url.url)
			free(event->event.url.url);
		break;
	case IAX_EVENT_AUTHRQ:
		if (event->event.authrequest.challenge)
			free(event->event.authrequest.challenge);
		if (event->event.authrequest.username)
			free(event->event.authrequest.username);
		break;
	case IAX_EVENT_AUTHRP:
		if (event->event.authreply.reply)
			free(event->event.authreply.reply);
		break;
	case IAX_EVENT_REGREQ:
		if (event->event.regrequest.server)
			free(event->event.regrequest.server);
		if (event->event.regrequest.peer)
			free(event->event.regrequest.peer);
		if (event->event.regrequest.secret)
			free(event->event.regrequest.secret);
		break;
	case IAX_EVENT_REGREP:
		if (event->event.regreply.ourip)
			free(event->event.regreply.ourip);
		if (event->event.regreply.callerid)
			free(event->event.regreply.callerid);
		break;
	case IAX_EVENT_TRANSFER:
		if (event->event.transfer.newip)
			free(event->event.transfer.newip);
		break;
	case IAX_EVENT_DPREQ:
		if (event->event.dpreq.number)
			free(event->event.dpreq.number);
		break;
	case IAX_EVENT_DPREP:
		if (event->event.dprep.number)
			free(event->event.dprep.number);
		break;
	case IAX_EVENT_DIAL:
		if (event->event.dial.number)
			free(event->event.dial.number);
		break;
	case IAX_EVENT_DTMF:
	case IAX_EVENT_ACCEPT:
	case IAX_EVENT_ANSWER:
	case IAX_EVENT_BUSY:
	case IAX_EVENT_LAGRQ:
	case IAX_EVENT_LAGRP:
	case IAX_EVENT_RINGA:
	case IAX_EVENT_PING:
	case IAX_EVENT_PONG:
	case IAX_EVENT_LDCOMPLETE:
	case IAX_EVENT_QUELCH:
	case IAX_EVENT_UNQUELCH:
	case IAX_EVENT_UNLINK:
	case IAX_EVENT_LINKREJECT:
		break;
	default:
		DEBU(G "Don't know how to free events of type %d\n", event->etype);
	}
	free(event);
}

int iax_get_fd(void) 
{
	/* Return our network file descriptor.  The client can select on this (probably with other
	   things, or can add it to a network add sort of gtk_input_add for example */
	return netfd;
}
