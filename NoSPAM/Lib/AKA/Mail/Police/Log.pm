#
# 北京互联网接警中心邮件过滤器
# Company: AKA Information & Technology Co., Ltd.
# Author: Ed Lee
# EMail: zixia@zixia.net
# Date: 2004-02-10


package AKA::Mail::Police::Log;
use AKA::Mail::Police::Verify;


use XML::Simple;
use POSIX qw(strftime);

my $can_log = 1;

BEGIN
{
	open MYLOG, ">>/var/log/police" or $can_log = 0;
}

sub new
{
# Retrieve the package's string.
# It is not necessarily Foo, because this constructor may be
# called from a class that inherits Foo.
	my $class = shift;

# $self is the the object. Let's initialize it to an empty hash
# reference.
	my $self = {};

# Associate $self with the class $class. This is probably the most
# important step.
	bless $self, $class;

	my $parent = shift;

	$self->{parent} = $parent;
	$self->{conf} = $parent->{conf} || new AKA::Mail::Police::Conf;
	$self->{verify} = $parent->{verify} || new AKA::Mail::Police::Verify;
# Now we can retrieve the other arguments passed to the 
# construtor.

	#my $name = shift || "Fooish";
	#my $number = shift || 5;

# Put these arguments inside class members
	#$self->{'number'} = 5;

# Return $self so the user can use it.
	return $self;

}

sub log
{
	my ($slef,$what) = @_;

# Strip the string of newline characters
	$what =~ s/\n//g;

# The MYLOG filehandle is already open by virtue of the BEGIN
# block.
	if ( $can_log ){
		print MYLOG &get_time_stamp . " $what\n";
	}
}

sub get_time_stamp
{
	strftime "%Y%m%d%H%M%S", localtime;
}

sub DESTROY
{
    my $self = shift;

    #print "DESTROYed.\n";
}


END
{
	close(MYLOG);
}

1;



