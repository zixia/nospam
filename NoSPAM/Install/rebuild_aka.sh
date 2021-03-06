#!/bin/sh

# cpperl src.pl dst.pl
cpperl()
{
	echo "cpperl $1 to $2..."
	echo '#!/usr/bin/perl -X -I/home/NoSPAM' > $2;
	# 这个导致 ns-queue 没有输出了？echo 'open (NSOUT, ">&=2"); open(STDERR,">/dev/null");' >> $2;
	echo 'my $AKA_noSPAM_release = 1;' >> $2;
	cat $1 >> $2;
}

cpperl_T()
{
	echo "cpperl_T $1 to $2..."
	echo '#!/usr/bin/perl -TX -I/home/NoSPAM' > $2;
	echo 'open (NSOUT, ">&=2"); close STDERR;' >> $2;
	echo 'my $AKA_noSPAM_release = 1;' >> $2;
	cat $1 >> $2;
}


SOURCEHOME="/NoSPAM/"

echo "Making perl module directorys"
mkdir -p aka/usr/lib/perl5/site_perl/5.8.0/i386-linux-thread-multi/auto/AKA/
mkdir -p aka/usr/lib/perl5/site_perl/5.8.0/AKA/Mail/Police/Conf
mkdir -p aka/root
mkdir -p aka/home/NoSPAM/bin
mkdir -p aka/home/NoSPAM/LocaleData/{zh_CN,en_US}/LC_MESSAGES
mkdir -p aka/var/qmail/bin

#####
#
# I18N Translations.
#
#####
cd ../Locale; make; cd -
cp ../Locale/engine.nospam.cn.mo aka/home/NoSPAM/LocaleData/zh_CN/LC_MESSAGES
cp ../Locale/web.nospam.cn.mo aka/home/NoSPAM/LocaleData/zh_CN/LC_MESSAGES

######
#
# Perl Modules
#
########
echo "Deleting old file..."
rm -fvr aka/usr/lib/perl5/site_perl/5.8.0/AKA/

echo "Copying source files..."
cp -Rv ${SOURCEHOME}/Lib/AKA aka/usr/lib/perl5/site_perl/5.8.0/

echo "Deleteing Loader source & CVS:"
rm -fvr aka/usr/lib/perl5/site_perl/5.8.0/AKA/Loader
find aka/usr/lib/perl5/site_perl/5.8.0/AKA | grep CVS | xargs rm -fr
find aka/usr/lib/perl5/site_perl/5.8.0/AKA -name tags | xargs rm -f

echo "Encrypting..."
find aka/usr/lib/perl5/site_perl/5.8.0/AKA | grep pm$ | grep -v CVS | grep -v Loader | xargs ${SOURCEHOME}/Admin/factory/encrypt 


######
#
# NoSPAM Utils
#
########3
echo "Deleting old file..."
rm -fvr aka/home/NoSPAM/bin/{NoSPAM,ns-daemon,ns-daemon_ex,ga-daemon,smtp_auth_proxy,UpdateRule,UploadLog}
rm -fvr aka/root/post_install

echo "Copying source files..."
cpperl ${SOURCEHOME}/Bin/NoSPAM.pl aka/home/NoSPAM/bin/NoSPAM.pl
cpperl ${SOURCEHOME}/Bin/ns-daemon.pl aka/home/NoSPAM/bin/ns-daemon.pl
cpperl ${SOURCEHOME}/Bin/ns-daemon_ex.pl aka/home/NoSPAM/bin/ns-daemon_ex.pl
cpperl ${SOURCEHOME}/Bin/ga-daemon.pl aka/home/NoSPAM/bin/ga-daemon.pl
cpperl ${SOURCEHOME}/Bin/smtp_auth_proxy.pl aka/home/NoSPAM/bin/smtp_auth_proxy.pl
cpperl ${SOURCEHOME}/Bin/rrdgraph.pl aka/home/NoSPAM/bin/rrdgraph.pl
cpperl_T ${SOURCEHOME}/Bin/cli.pl aka/home/NoSPAM/bin/cli.pl
chmod 755 aka/home/NoSPAM/bin/*.pl
cpperl ${SOURCEHOME}/Bin/NoSPAM.pl aka/root/post_install.pl
chmod 755 aka/root/*.pl

# 2004-05-23 qns_loaer.cpp 替换掉 qns_loader.c & ns-queue.pl
#cpperl ${SOURCEHOME}/Bin/ns-queue.pl aka/var/qmail/bin/ns-queue.pl
#chmod 755 aka/var/qmail/bin/ns-queue.pl

#rm -f aka/var/qmail/bin/ins-queue
#ln -s ns-queue aka/var/qmail/bin/ins-queue

echo "Encrypting..."
${SOURCEHOME}/Admin/factory/encrypt aka/home/NoSPAM/bin/*.pl
${SOURCEHOME}/Admin/factory/encrypt aka/root/*.pl
${SOURCEHOME}/Admin/factory/encrypt aka/var/qmail/bin/*.pl

echo "Compiling qns_loader & wi  source"
cd ${SOURCEHOME}/Bin
make qns_loader
make wi
cd -
cp ${SOURCEHOME}/Bin/{wi,qns_loader} aka/home/NoSPAM/bin/

echo "Changing qns_loader & wi permission"
chown root aka/home/NoSPAM/bin/{qns_loader,wi}
chmod +s aka/home/NoSPAM/bin/{qns_loader,wi}
chmod -R o+r aka/* 
chmod 755 aka/home/NoSPAM/bin/cli

echo "Cleaning cvs,test rubbish"
find aka -type f -name ".#*" -exec rm -fv {} \;
find aka -type f -name "*.pl" -exec rm -fv {} \;

