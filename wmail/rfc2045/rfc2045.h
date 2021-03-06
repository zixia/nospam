/*
** Copyright 1998 - 2003 Double Precision, Inc.  See COPYING for
** distribution information.
*/

/*
** $Id$
*/
#ifndef	rfc2045_h
#define	rfc2045_h

#include	"../rfc2045/rfc2045_config.h" /* VPATH build */
#include	<sys/types.h>
#include	<string.h>
#include	<stdio.h>

#ifdef  __cplusplus
extern "C" {
#endif

#define	RFC2045_ISMIME1(p)	((p) && atoi(p) == 1)
#define	RFC2045_ISMIME1DEF(p)	(!(p) || atoi(p) == 1)

struct rfc2045 {
	struct rfc2045 *parent;
	unsigned pindex;
	struct rfc2045 *next;

	off_t	startpos,	/* At which offset in msg this section starts */
		endpos,		/* Where it ends */
		startbody,	/* Where the body of the msg starts */
		endbody;	/* endpos - trailing CRLF terminator */
	off_t	nlines;		/* Number of lines in message */
	off_t	nbodylines;	/* Number of lines only in the body */
	char *mime_version;
	char *content_type;
	struct rfc2045attr *content_type_attr;	/* Content-Type: attributes */

	char *content_disposition;
	char *boundary;
	struct rfc2045attr *content_disposition_attr;
	char *content_transfer_encoding;
	int content_8bit;		/*
					** Set if content_transfer_encoding is
					** 8bit
					*/
	char *content_id;
	char *content_description;
	char *content_language;
	char *content_md5;
	char *content_base;
	char *content_location;
	struct  rfc2045ac *rfc2045acptr;
	int	has8bitchars;	/* For rewriting */
	int	haslongline;	/* For rewriting */
	unsigned rfcviolation;	/* Boo-boos */

#define	RFC2045_ERR8BITHEADER	1	/* 8 bit characters in headers */
#define	RFC2045_ERR8BITCONTENT	2	/* 8 bit contents, but no 8bit
					content-transfer-encoding */
#define	RFC2045_ERR2COMPLEX	4	/* Too many nested contents */
#define RFC2045_ERRBADBOUNDARY	8	/* Overlapping MIME boundaries */

	unsigned numparts;	/* # of parts allocated */

	char	*rw_transfer_encoding;	/* For rewriting */

#define	RFC2045_RW_7BIT	1
#define	RFC2045_RW_8BIT	2

	/* Subsections */

	struct rfc2045 *firstpart, *lastpart;

	/* Working area */

	char *workbuf;
	size_t workbufsize;
	size_t workbuflen;
	int	workinheader;
	int	workclosed;
	int	isdummy;
	int	informdata;	/* In a middle of a long form-data part */
	char *header;
	size_t headersize;
	size_t headerlen;

	int	(*decode_func)(struct rfc2045 *, const char *, size_t);
	void	*misc_decode_ptr;
	int	(*udecode_func)(const char *, size_t, void *);
} ;

struct rfc2045attr {
	struct rfc2045attr *next;
	char *name;
	char *value;
	} ;

struct rfc2045 *rfc2045_alloc();
void rfc2045_parse(struct rfc2045 *, const char *, size_t);
void rfc2045_parse_partial(struct rfc2045 *);
void rfc2045_free(struct rfc2045 *);

void rfc2045_mimeinfo(const struct rfc2045 *,
	const char **,
	const char **,
	const char **);

const char *rfc2045_boundary(const struct rfc2045 *);
	int rfc2045_isflowed(const struct rfc2045 *);
char *rfc2045_related_start(const struct rfc2045 *);
const char *rfc2045_content_id(const struct rfc2045 *);
const char *rfc2045_content_description(const struct rfc2045 *);
const char *rfc2045_content_language(const struct rfc2045 *);
const char *rfc2045_content_md5(const struct rfc2045 *);

void rfc2045_mimepos(const struct rfc2045 *, off_t *, off_t *, off_t *,
	off_t *, off_t *);
unsigned rfc2045_mimepartcount(const struct rfc2045 *);

void rfc2045_xdump(struct rfc2045 *);

struct rfc2045id {
	struct rfc2045id *next;
	int idnum;
} ;

void rfc2045_decode(struct rfc2045 *,
	void (*)(struct rfc2045 *, struct rfc2045id *, void *),
	void *);

struct rfc2045 *rfc2045_find(struct rfc2045 *, const char *);


void rfc2045_cdecode_start(struct rfc2045 *,
	int (*)(const char *, size_t, void *), void *);
int rfc2045_cdecode(struct rfc2045 *, const char *, size_t);
int rfc2045_cdecode_end(struct rfc2045 *);

struct rfc2045_encode_info {
	char output_buffer[BUFSIZ];
	int output_buf_cnt;

	char input_buffer[57]; /* For base64 */
	int input_buf_cnt;

	int (*encoding_func)(struct rfc2045_encode_info *,
			     const char *, size_t);
	int (*callback_func)(const char *, size_t, void *);
	void *callback_arg;
};

const char *rfc2045_encode_autodetect_fp(FILE *, int okQp);

void rfc2045_encode_start(struct rfc2045_encode_info *info,
			  const char *transfer_encoding,
			  int (*callback_func)(const char *, size_t, void *),
			  void *callback_arg);

int rfc2045_encode(struct rfc2045_encode_info *info,
		   const char *ptr,
		   size_t cnt);

int rfc2045_encode_end(struct rfc2045_encode_info *info);

const char *rfc2045_getdefaultcharset();
void rfc2045_setdefaultcharset(const char *);
struct rfc2045 *rfc2045_fromfd(int);
#define	rfc2045_fromfp(f)	(rfc2045_fromfd(fileno((f))))
struct rfc2045 *rfc2045header_fromfd(int);
#define        rfc2045header_fromfp(f)        (rfc2045header_fromfd(fileno((f))))

extern void rfc2045_error(const char *);


struct  rfc2045ac {
	void (*start_section)(struct rfc2045 *);
	void (*section_contents)(const char *, size_t);
	void (*end_section)();
	} ;

struct rfc2045 *rfc2045_alloc_ac();
int rfc2045_ac_check(struct rfc2045 *, int);
int rfc2045_rewrite(struct rfc2045 *, int, int, const char *);
int rfc2045_rewrite_func(struct rfc2045 *p, int,
	int (*)(const char *, int, void *), void *,
	const char *);

/* Internal functions */

int rfc2045_try_boundary(struct rfc2045 *, int, const char *);
char *rfc2045_mk_boundary(struct rfc2045 *, int);
const char *rfc2045_getattr(const struct rfc2045attr *, const char *);
void rfc2045_setattr(struct rfc2045attr **, const char *, const char *);

/* MIME content base/location */

char *rfc2045_content_base(struct rfc2045 *p);
	/* This joins Content-Base: and Content-Location:, as best as I
	** can figure it out.
	*/

char *rfc2045_append_url(const char *, const char *);
	/* Do this with two arbitrary URLs */

/* MISC mime functions */

struct rfc2045 *rfc2045_searchcontenttype(struct rfc2045 *, const char *);
	/* Assume that the "real" message text is the first MIME section here
	** with the given content type.
	*/

int rfc2045_decodemimesection(int,	/* File descriptor */
			      struct rfc2045 *,	/* MIME section to decode */
			      int (*)(const char *, size_t, void *),
			      /*
			      ** Callback function that receives decoded
			      ** content.
			      */
			      void *	/* 3rd arg to the callback function */
			      );
	/*
	** Decode a given MIME section.
	*/

int rfc2045_decodetextmimesection(int,	/* File descriptor */
				  struct rfc2045 *, /* MIME section */
				  const char *,	/* Character set */
				  int (*)(const char *, size_t, void *),
				  /*
				  ** Callback function that receives decoded
				  ** content.
				  */
				  void * /* 3rd arg to the callback function */
			      );
	/*
	** Like decodemimesction(), except that the text is automatically
	** convert to the specified character set (this function falls back
	** to decodemimesection() if libunicode.a is not available, or if
	** either the specified character set, or the MIME character set
	** is not supported by libunicode.a
	*/


	/*
	** READ HEADERS FROM A MIME SECTION.
	**
	** Call rfc2045header_start() to allocate a structure for the given
	** MIME section.
	**
	** Call rfc2045header_get() to repeatedly get the next header.
	** Function returns < 0 for a failure (out of memory, or something
	** like that).  Function returns 0 for a success.  Example:
	**
	** rfc2045header_get(ptr, &header, &value, 0);
	**
	** If success: check if header is NULL - end of headers, else
	** "header" and "value" will contain the RFC 822 header.
	**
	** Last argument is flags:
	*/

#define RFC2045H_NOLC 1		/* Do not convert header to lowercase */
#define RFC2045H_KEEPNL 2	/* Preserve newlines in the value string
				** of multiline headers.
				*/

struct rfc2045headerinfo *
	rfc2045header_start(int,	/* Readonly file descriptor */
			    struct rfc2045 *	/* MIME section to read */
			    );

int rfc2045header_get(struct rfc2045headerinfo *,
		      char **,	/* Header return */
		      char **,	/* Value return */
		      int);	/* Flags */

void rfc2045header_end(struct rfc2045headerinfo *);

/*
** The rfc2045_makereply function is used to generate an initial
** reply to a MIME message.  rfc2045_makereply takes the following
** structure:
*/

struct rfc2045_mkreplyinfo {

	int fd;	/* Readonly seekable filedescriptor for the original message */

	struct rfc2045 *rfc2045partp;
	/*
	** rfc2045 structure for the message to reply.  This may actually
	** represent a single message/rfc822 section within a larger MIME
	** message digest, in which case we format a reply to this message.
	*/

	void *voidarg;	/* Transparent argument passed to the callback
			** functions.
			*/

	/*
	** The following callback functions are called to generate the reply
	** message.  They must be initialized.
	*/

	void (*write_func)(const char *, size_t, void *);
	/* Called to write out the content of the message */

	void (*writesig_func)(void *);
	/* Called to write out the sender's signature */

	int (*myaddr_func)(const char *, void *);
	/* myaddr_func receives a pointer to an RFC 822 address, and it
	** should return non-zero if the address is the sender's address
	*/

	const char *replymode;
	/*
	** replymode must be initialized to one of the following.  It sets
	** the actual template for the generated response.
	**
	** "forward" - forward original message.
	** "forwardatt" - forward original message as an RFC822 attachment
	** "reply" - a standard reply to the original message's sender
	** "replyall" - a "reply to all" response.
	** "replylist" - "reply to mailing list" response.  This is a reply
	** that's addressed to the mailing list the original message was sent
	** to.
	*/

	const char *replysalut;
	/*
	** This should be set to the salutation to be used for the reply.
	** %s is replaced by the sender's name.  Example:  "%s writes:"
	*/

	const char *forwarddescr;
	/*
	** For forwardatt, this is the Content-Description: header,
	** (typically "Forwarded message").
	*/

	const char *mailinglists;
	/*
	** This should be set to a whitespace-delimited list of mailing list
	** RFC 822 addresses that the respondent is subscribed to.  It is used
	** to figure out which mailing list the original message was sent to
	** (all addresses in the original message are compared against this
	** list).  In the event that we can't find a mailing list address on
	** the original message, "replylist" will fall back to "replyall".
	*/

	const char *charset;
	/* The respondent's local charset */

	const char *forwardsep;
	/* This is used instead of replysalut for forwards. */

	/* INTERNAL VARIABLES: */

	int start_line;

	void (*decodesectionfunc)(int, struct rfc2045 *, const char *,
				  int (*)(const char *, size_t, void *),
				  void *);
} ;

int rfc2045_makereply(struct rfc2045_mkreplyinfo *);
int rfc2045_makereply_unicode(struct rfc2045_mkreplyinfo *);
	/*
	** Like makereply(), except do unicode translation from message text
	** to charset.
	*/

/********** Decode RFC 2231 attributes ***********/

/*
** rfc2231_decodeType() decodes an RFC 2231-encoded Content-Type: header
** attribute, and rfc2231_decodeDisposition() decodes the attribute in the
** Content-Disposition: header.
**
** chsetPtr, langPtr, and textPtr should point to a char ptr.  These
** functions automatically allocate the memory, the caller's responsible for
** freeing it.  A NULL argument may be provided if the corresponding
** information is not wanted.
*/

int rfc2231_decodeType(struct rfc2045 *rfc, const char *name,
		       char **chsetPtr,
		       char **langPtr,
		       char **textPtr);

int rfc2231_decodeDisposition(struct rfc2045 *rfc, const char *name,
			      char **chsetPtr,
			      char **langPtr,
			      char **textPtr);

/*
** The following two functions convert the decoded string to the local
** charset via unicodelib.  textPtr cannot be null, this time, because this
** is the only return value.   A NULL myChset is an alias for the default
** charset.
*/

struct unicode_info;

int rfc2231_udecodeType(struct rfc2045 *rfc, const char *name,
			const struct unicode_info *myChset,
			char **textPtr);

int rfc2231_udecodeDisposition(struct rfc2045 *rfc, const char *name,
			       const struct unicode_info *myChset,
			       char **textPtr);

/*
** Build an RFC 2231-encoded name*=value.
**
** *lenPtr= # of characters, including \0.
** strPtr= name*=value written here, if strPtr not NULL.
** Call once to get the length of the buffer, then do it for real once more.
**
*/

void rfc2231_attrCreate(const char *name, const char *value,
			const char *charset, char *strPtr,
			int *lenPtr, const char *language);

/** NON-PUBLIC DATA **/

struct rfc2231param {
	struct rfc2231param *next;

	int paramnum;
	int encoded;

	const char *value;
};

void rfc2231_paramDestroy(struct rfc2231param *paramList);
int rfc2231_buildAttrList(struct rfc2231param **paramList,
			  const char *name,

			  const char *attrName,
			  const char *attrValue);

void rfc2231_paramDecode(struct rfc2231param *paramList,
			 char *charsetPtr,
			 char *langPtr,
			 char *textPtr,
			 int *charsetLen,
			 int *langLen,
			 int *textLen);


#ifdef  __cplusplus
}
#endif

#endif
