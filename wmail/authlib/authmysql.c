/*
** Copyright 2000-2001 Double Precision, Inc.  See COPYING for
** distribution information.
*/
#if	HAVE_CONFIG_H
#include	"config.h"
#endif
#include	<stdio.h>
#include	<stdlib.h>
#include	<string.h>
#include	<errno.h>
#include	<pwd.h>
#if	HAVE_UNISTD_H
#include	<unistd.h>
#endif

#include	"auth.h"
#include	"authmod.h"
#include	"authmysql.h"
#include	"authstaticlist.h"

static const char rcsid[]="$Id$";

static char *auth_mysql_login(const char *service, char *authdata,
	int issession,
	void (*callback_func)(struct authinfo *, void *), void *callback_arg)
{
char *user, *pass;
struct authmysqluserinfo *authinfo;

	if ((user=strtok(authdata, "\n")) == 0 ||
		(pass=strtok(0, "\n")) == 0)
	{
		errno=EPERM;
		return (0);
	}

	authinfo=auth_mysql_getuserinfo(user);

	if (!callback_func)
		auth_mysql_cleanup();

	if (!authinfo)		/* Fatal error - such as MySQL being down */
	{
		errno=EACCES;
		return (0);
	}

	if (authinfo->cryptpw)
	{
		if (authcheckpassword(pass,authinfo->cryptpw))
		{
			errno=EPERM;
			return (0);	/* User/Password not found. */
		}
	}
	else if (authinfo->clearpw)
	{
		if (strcmp(pass, authinfo->clearpw))
		{
			errno=EPERM;
			return (0);
		}
	}
	else
	{
		errno=EPERM;
		return (0);		/* Username not found */
	}

	if (callback_func == 0)
	{
	static char *maildir=0;
	static char *quota=0;

		authsuccess(authinfo->home, 0, &authinfo->uid,
			    &authinfo->gid, authinfo->username,
			    authinfo->fullname ? authinfo->fullname:"");

		if (authinfo->maildir && authinfo->maildir[0])
		{
			if (maildir)	free(maildir);
			maildir=malloc(sizeof("MAILDIR=")+
					strlen(authinfo->maildir));
			if (!maildir)
			{
				perror("malloc");
				exit(1);
			}
			strcat(strcpy(maildir, "MAILDIR="), authinfo->maildir);
			putenv(maildir);
		}
		else
		{
			putenv("MAILDIR=");
		}

		if (authinfo->quota && authinfo->quota[0])
                {
                        if (quota)    free(quota);
                        quota=malloc(sizeof("MAILDIRQUOTA=")+
                                        strlen(authinfo->quota));
                        if (!quota)
                        {
                                perror("malloc");
                                exit(1);
                        }
                        strcat(strcpy(quota, "MAILDIRQUOTA="), authinfo->quota);
                        putenv(quota);
                }
                else
                {
                        putenv("MAILDIRQUOTA=");
                }
	}
	else
	{
	struct	authinfo	aa;

		memset(&aa, 0, sizeof(aa));

		/*aa.sysusername=user;*/
		aa.sysuserid= &authinfo->uid;
		aa.sysgroupid= authinfo->gid;
		aa.homedir=authinfo->home;
		aa.maildir=authinfo->maildir && authinfo->maildir[0] ?
			authinfo->maildir:0;
		aa.address=authinfo->username;
		aa.quota=authinfo->quota && authinfo->quota[0] ?
			authinfo->quota:0;
		aa.fullname=authinfo->fullname;
		(*callback_func)(&aa, callback_arg);
	}

	return (strdup(authinfo->username));
}

static int auth_mysql_changepw(const char *service, const char *user,
				 const char *pass,
				 const char *newpass)
{
struct authmysqluserinfo *authinfo;

	authinfo=auth_mysql_getuserinfo(user);

	if (!authinfo)
	{
		errno=ENOENT;
		return (-1);
	}

	if (authinfo->cryptpw)
	{
		if (authcheckpassword(pass,authinfo->cryptpw))
		{
			errno=EPERM;
			return (-1);	/* User/Password not found. */
		}
	}
	else if (authinfo->clearpw)
	{
		if (strcmp(pass, authinfo->clearpw))
		{
			errno=EPERM;
			return (-1);
		}
	}
	else
	{
		errno=EPERM;
		return (-1);
	}

	if (auth_mysql_setpass(user, newpass))
	{
		errno=EPERM;
		return (-1);
	}
	return (0);
}

#if HAVE_HMACLIB

#include	"../libhmac/hmac.h"
#include	"cramlib.h"

struct cram_callback_info {
	struct hmac_hashinfo *h;
	char *user;
	char *challenge;
	char *response;
	char *userret;
	int issession;
	void (*callback_func)(struct authinfo *, void *);
	void *callback_arg;
	};

static int callback_cram(struct authinfo *a, void *vp)
{
struct cram_callback_info *cci=(struct cram_callback_info *)vp;
unsigned char *hashbuf;
unsigned char *p;
unsigned i;
static const char hex[]="0123456789abcdef";
int	rc;

	if (!a->clearpasswd)
		return (-1);

	/*
		hmac->hh_L*2 will be the size of the binary hash.

		hmac->hh_L*4+1 will therefore be size of the binary hash,
		as a hexadecimal string.
	*/

	if ((hashbuf=malloc(cci->h->hh_L*6+1)) == 0)
		return (1);

	hmac_hashkey(cci->h, a->clearpasswd, strlen(a->clearpasswd),
		hashbuf, hashbuf+cci->h->hh_L);

	p=hashbuf+cci->h->hh_L*2;

	for (i=0; i<cci->h->hh_L*2; i++)
	{
	char	c;

		c = hex[ (hashbuf[i] >> 4) & 0x0F];
		*p++=c;

		c = hex[ hashbuf[i] & 0x0F];
		*p++=c;

		*p=0;
	}

	rc=auth_verify_cram(cci->h, cci->challenge, cci->response,
		(const char *)hashbuf+cci->h->hh_L*2);
	free(hashbuf);

	if (rc)	return (rc);

	if ((cci->userret=strdup(a->address)) == 0)
	{
		perror("malloc");
		return (1);
	}

	if (cci->callback_func)
		(*cci->callback_func)(a, cci->callback_arg);
	else
	{
		authsuccess(a->homedir, a->sysusername, a->sysuserid,
			&a->sysgroupid,
			a->address,
			a->quota);

		if (a->maildir && a->maildir[0])
		{
		static char *maildir=0;

			if (maildir)	free(maildir);
			maildir=malloc(sizeof("MAILDIR=")+strlen(a->maildir));
			if (!maildir)
			{
				perror("malloc");
				exit(1);
			}
			strcat(strcpy(maildir, "MAILDIR="), a->maildir);
			putenv(maildir);
		}
		else
		{
			putenv("MAILDIR=");
		}
	}

	return (0);
}

static char *auth_mysql_cram(const char *service,
	const char *authtype, char *authdata, int issession,
	void (*callback_func)(struct authinfo *, void *), void *callback_arg)
{
struct	cram_callback_info	cci;
int	rc;

	if (auth_get_cram(authtype, authdata,
		&cci.h, &cci.user, &cci.challenge, &cci.response))
		return (0);

	cci.issession=issession;
	cci.callback_func=callback_func;
	cci.callback_arg=callback_arg;

	rc=auth_mysql_pre(cci.user, service, &callback_cram, &cci);

	if (callback_func == 0)
		auth_mysql_cleanup();

	if (rc < 0)
	{
		errno=EPERM;
		return (0);
	}
	if (rc > 0)
	{
		errno=EACCES;
		return (0);
	}
	return (cci.userret);
}
#endif

char *auth_mysql(const char *service, const char *authtype, char *authdata,
		int issession,
	void (*callback_func)(struct authinfo *, void *), void *callback_arg)
{
	if (strcmp(authtype, AUTHTYPE_LOGIN) == 0)
		return (auth_mysql_login(service, authdata, issession,
			callback_func, callback_arg));

#if HAVE_HMACLIB
	return (auth_mysql_cram(service, authtype, authdata, issession,
			callback_func, callback_arg));
#else
	errno=EPERM;
	return (0);
#endif
}

extern int auth_mysql_pre(const char *user, const char *service,
			  int (*callback)(struct authinfo *, void *),
			  void *arg);

struct authstaticinfo authmysql_info={
	"authmysql",
	auth_mysql,
	auth_mysql_pre,
	auth_mysql_cleanup,
	auth_mysql_changepw,
	NULL};
