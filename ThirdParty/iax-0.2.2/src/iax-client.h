/*
 * Asterisk -- A telephony toolkit for Linux.
 *
 * Implementation of Inter-Asterisk eXchange
 * 
 * Copyright (C) 1999, Mark Spencer
 *
 * Mark Spencer <markster@linux-support.net>
 *
 * This program is free software, distributed under the terms of
 * the GNU General Public License
 */
 
#ifndef _ASTERISK_IAX_CLIENT_H
#define _ASTERISK_IAX_CLIENT_H

#include "frame.h"

#define MAXSTRLEN 80

#define IAX_AUTHMETHOD_PLAINTEXT 1
#define IAX_AUTHMETHOD_MD5 2

extern char iax_errstr[];

struct iax_session;

struct iax_connect_request {
	char *callerid;		/* Caller-ID reported by caller (not trustworthy) */
	char *dnid;			/* Dialed Number Information Digits (DID) */
	char *context;		/* Requested context (Typically used by Asterisk) */
	char *exten;		/* Extension */
	char *username;		/* Desired username to connect as */
	char *hostname;		/* Desired hostname to connect to */
	char *secret;		/* Secret if known for call */
	char *language;		/* Preferred language */
	short portno;		/* Desired port number to connect to */
	int formats;		/* Supported formats of caller (see frame.h) */
	int version;		/* Protocol version */
};

struct iax_text {
	char text[8192];
};

struct iax_transfer {
	char *newip;
	int newport;
};

struct iax_authentication_request {
	int authmethods;				/* See above definitions (IAX_AUTHMETHOD_*) */
	char *challenge;		/* Challenge string (MD5 only) -- 
										see iax_generate_challenge and 
										    iax_apply_challenge */
	char *username;		/* User caller must authenticate as */
	
};

#define IAX_REG_SUCCESS	1
#define IAX_REG_REJECT	2
#define IAX_REG_TIMEOUT	3

struct iax_registration_reply {
	int status;
	char *ourip;
	char *callerid;
	short ourport;
	int refresh;
};

struct iax_registration_request {
	char *server;
	short portno;
	char *peer;
	char *secret;
	int refresh;
};

struct iax_authentication_reply {
	int authmethod;					/* Reply Authentication method */
	char *reply;			/* Actual authentication reply */
};

struct iax_rejection {
	char *reason;
};

struct iax_hangup {
	char *byemsg;
};

struct iax_lag {
	int lag;
	int jitter;
};

struct iax_lagrq {
	unsigned int ts;
};

struct iax_ping {
	unsigned int ts;
	unsigned short seqno;
};

struct iax_dtmf {
	char digit;
};

struct iax_voice {
	int format;
	void *data;
	int datalen;
};
	
struct iax_image {
	int format;
	void *data;
	int datalen;
};

struct iax_event_url {
	int link;
	char *url;
};

struct iax_event_linkrej {
};

struct iax_dial {
	char *number;
};

struct iax_dialplan_request {
	char *number;
};

struct iax_dialplan_reply {
	char *number;
	int exists;
	int canexist;
	int nonexistant;
	int ignorepat;
	int expirey;
};
	

#define IAX_EVENT_CONNECT 0			/* Connect a new call */
#define IAX_EVENT_ACCEPT  1			/* Accept a call */
#define IAX_EVENT_HANGUP  2			/* Hang up a call */
#define IAX_EVENT_REJECT  3			/* Rejected call */
#define IAX_EVENT_VOICE   4			/* Voice Data */
#define IAX_EVENT_DTMF    5			/* A DTMF Tone */
#define IAX_EVENT_TIMEOUT 6			/* Connection timeout...  session will be
									   a pointer to free()'d memory! */
#define IAX_EVENT_LAGRQ   7			/* Lag request -- Internal use only */
#define IAX_EVENT_LAGRP   8			/* Lag Measurement.  See event.lag */
#define IAX_EVENT_RINGA	  9			/* Announce we/they are ringing */
#define IAX_EVENT_PING	  10		/* Ping -- internal use only */
#define IAX_EVENT_PONG	  11		/* Pong -- internal use only */
#define IAX_EVENT_BUSY	  12		/* Report a line busy */
#define IAX_EVENT_ANSWER  13		/* Answer the line */

#define IAX_EVENT_IMAGE   14		/* Send/Receive an image */
#define IAX_EVENT_AUTHRQ  15		/* Authentication request */
#define IAX_EVENT_AUTHRP  16		/* Authentication reply */

#define IAX_EVENT_REGREQ  17		/* Registration request */
#define IAX_EVENT_REGREP  18		/* Registration reply */
#define IAX_EVENT_URL	  19		/* URL received */
#define IAX_EVENT_LDCOMPLETE 20		/* URL loading complete */

#define IAX_EVENT_TRANSFER	21		/* Transfer has taken place */

#define IAX_EVENT_DPREQ		22		/* Dialplan request */
#define IAX_EVENT_DPREP		23		/* Dialplan reply */
#define IAX_EVENT_DIAL		24		/* Dial on a TBD call */

#define IAX_EVENT_QUELCH	25		/* Quelch Audio */
#define IAX_EVENT_UNQUELCH	26		/* Unquelch Audio */

#define IAX_EVENT_UNLINK	27		/* Unlink */
#define IAX_EVENT_LINKREJECT	28		/* Link Rejection */
#define IAX_EVENT_TEXT		29		/* Text Frame :-) */

#define IAX_SCHEDULE_FUZZ 0			/* ms of fuzz to drop */

struct iax_event {
	int etype;						/* Type of event */
	struct iax_session *session;	/* Applicable session */
	union {
		struct iax_connect_request		connect;
		struct iax_authentication_request	authrequest;
		struct iax_authentication_reply		authreply;
		struct iax_transfer			transfer;
		struct iax_rejection			reject;
		struct iax_lagrq			lagrq;
		struct iax_ping				ping;
		struct iax_lag				lag;
		struct iax_dtmf				dtmf;
		struct iax_voice			voice;
		struct iax_hangup			hangup;
		struct iax_image			image;
		struct iax_registration_request		regrequest;
		struct iax_registration_reply		regreply;
		struct iax_event_url			url;
		struct iax_dialplan_request		dpreq;
		struct iax_dialplan_reply		dprep;
		struct iax_dial				dial;
		struct iax_text				text;
	} event;
};

/* All functions return 0 on success and -1 on failure unless otherwise
   specified */

/* Called to initialize IAX structures and sockets.  Returns actual
   portnumber (which it will try preferred portno first, but if not
   take what it can get */
extern int iax_init(int preferredportno);

/* Get filedescriptor for IAX to use with select or gtk_input_add */
extern int iax_get_fd(void);

/* Find out how many milliseconds until the next scheduled event */
extern int iax_time_to_next_event(void);

/* Generate a new IAX session */
extern struct iax_session *iax_session_new(void);

/* Transmit an IAX event -- Primary procedure for sending stuff */
extern int iax_do_event(struct iax_session *session, struct iax_event *event);

/* Return exactly one iax event (if there is one pending).  If blocking is
   non-zero, IAX will block until some event is received */
extern struct iax_event *iax_get_event(int blocking);


extern int iax_auth_reply(struct iax_session *session, char *password, 
						char *challenge, int methods);

/* Stop iax, hangup file descriptors, free memory, etc. */
extern void iax_end(void);

/* Free an event */
extern void iax_event_free(struct iax_event *event);

struct sockaddr_in;

/* Front ends for sending events */
extern void iax_set_formats(int fmt);
extern int iax_send_dtmf(struct iax_session *session, char digit);
extern int iax_send_voice(struct iax_session *session, int format, char *data, int datalen);
extern int iax_send_image(struct iax_session *session, int format, char *data, int datalen);
extern int iax_send_url(struct iax_session *session, char *url, int link);
extern int iax_send_text(struct iax_session *session, char *text);
extern int iax_load_complete(struct iax_session *session);
extern int iax_reject(struct iax_session *session, char *reason);
extern int iax_busy(struct iax_session *session);
extern int iax_hangup(struct iax_session *session, char *byemsg);
extern int iax_call(struct iax_session *session, char *callerid, char *ich, char *lang, int wait);
extern int iax_accept(struct iax_session *session);
extern int iax_answer(struct iax_session *session);
extern int iax_sendurl(struct iax_session *session, char *url);
extern int iax_send_unlink(struct iax_session *session);
extern int iax_send_link_reject(struct iax_session *session);
extern int iax_ring_announce(struct iax_session *session);
extern struct sockaddr_in iax_get_peer_addr(struct iax_session *session);
extern int iax_register(struct iax_session *session, char *hostname, char *peer, char *secret, int refresh);
extern int iax_lag_request(struct iax_session *session);
extern int iax_dial(struct iax_session *session, char *number);	/* Dial on a TBD call */
extern int iax_dialplan_request(struct iax_session *session, char *number);	/* Request dialplan status for number */
extern int iax_quelch(struct iax_session *session);
extern int iax_unquelch(struct iax_session * session);
#ifdef DEBUG_SUPPORT
extern int iax_enable_debug(void);
extern int iax_disable_debug(void);
#endif


#endif /* _ASTERISK_IAX_CLIENT_H */
