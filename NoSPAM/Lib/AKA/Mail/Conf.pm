#
# NoSPAM网关配置文件读取模块
# Company: AKA Information & Technology Co., Ltd.
# Author: Ed Lee
# EMail: zixia@zixia.net
# Date: 2004-02-29


package AKA::Mail::Conf;

use AKA::Mail::Log;

#use Exporter;
#use vars qw(@ISA @EXPORT);

#@ISA=qw(Exporter);

#@EXPORT=("function1", "function2", "function3");

#use Data::Dumper;
# 改变$转义、缩进
#$Data::Dumper::Useperl = 1;
#$Data::Dumper::Indent = 1;


sub new
{
	my $class = shift;
	my $self = {};

	bless $self, $class;

	my $parent = shift;

	$self->{parent} = $parent;

	$self->{define}->{home} = "/home/NoSPAM/";
	$self->{define}->{conffile} = $self->{define}->{home} . "/etc/gw.conf";

	$self->{zlog} = $parent->{zlog};

	return $self;
}


sub get_config
{
	my $self = shift;

	return $self->{config} if ( $self->{config} );

	use Config::Tiny;
	my $C = Config::Tiny->read( $self->{define}->{conffile} );

	my $config = $C->{_};

	$config->{ServerGateway} ||= "Gateway";

	$config->{Traceable} ||= "N";
	$config->{TraceType} = cut_comma_to_array_ref( $self,$config->{TraceType} );
	$config->{TraceSpamMask} ||= "16";
	$config->{TraceMaybeSpamMask} ||= "22";

	$config->{BlockFrom} ||= "N";
	$config->{BlackFromList} = cut_comma_to_array_ref( $self,$config->{BlackFromList} );
	$config->{WhiteFromList} = cut_comma_to_array_ref( $self,$config->{WhiteFromList} );

	$config->{BlockDomain} ||= "N";
	$config->{BlackDomainList} = cut_comma_to_array_ref( $self,$config->{BlackDomainList} );
	$config->{WhiteDomainList} = cut_comma_to_array_ref( $self,$config->{WhiteDomainList} );

	$config->{BlockIP} ||= "N";
	$config->{BlackIPList} = cut_comma_to_array_ref( $self,$config->{BlackIPList} );
	$config->{WhiteIPList} = cut_comma_to_array_ref( $self,$config->{WhiteIPList} );

	$config->{ConnPerIP} ||= 0;
	$config->{ConnRatePerIP} ||= "0/0";
	$config->{SendRatePerSubject} ||= "0/0";
	$config->{SendRatePerFrom} ||= "0/0";

	$config->{MailServerHostname} ||= "unknown.gw.nospam.aka.cn";
	#$config->{MailServerIP} 
	$config->{MailServerNetMask} ||= "24";
	#$config->{MailServerGateway}

	$config->{MailGatewayIP} ||= "10.10.10.10";

	$config->{SpamTag} ||= "【垃圾邮件】";
	$config->{MaybeSpamTag} ||= "【疑似垃圾】";

	$config->{RefuseSpam} ||= "N";

	$config->{ArchiveAble} ||= "N";
	$config->{ArchiveAdmin} ||= "archives\@localhost.localdomain";
	#$config->{ArchiveAddressOnly} 

	$config->{TagHead} ||= "Y";
	$config->{TagSubject} ||= "Y";
	$config->{TagReason} ||= "Y";

	$self->{config} = $config;
	return $self->{config};
}

sub cut_comma_to_array_ref
{
	my $self = shift;
	my $conf_line = shift;
	return undef if ( !defined $conf_line || !length($conf_line) );

	my @ret;
	foreach ( split(',', $conf_line) ){
		next if ( !defined $_ || !length($_) );
		push ( @ret, $_ );
	}

	return \@ret;
}

sub DESTROY
{
	my $self = shift;

	delete $self->{parent};

}

1;
