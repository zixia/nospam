#
# �����������Ӿ������ʼ�������
# Company: AKA Information & Technology Co., Ltd.
# Author: Ed Lee
# EMail: zixia@zixia.net
# Date: 2004-02-10

package AKA::Mail::Police::Rule;

use AKA::Mail::Police::Log;
use AKA::Mail::Police::Conf;
#use Exporter;
#use vars qw(@ISA @EXPORT);

#@ISA=qw(Exporter);

#@EXPORT=("function1", "function2", "function3");

#use Data::Dumper;
# �ı�$ת�塢����
#$Data::Dumper::Useperl = 1;
#$Data::Dumper::Indent = 1;

sub new
{
	my $class = shift;
	my $self = {};

	bless $self, $class;

	my ($parent) = shift;

	$self->{parent} = $parent;

	$self->{zlog} = $parent->{zlog} || new AKA::Mail::Police::Log($self) ;
	$self->{conf} = $parent->{conf} || new AKA::Mail::Police::Conf($self) ;

	return $self;
}

sub get_match_rule
{
	my $self = shift;
	
	my $mail_info = shift;

	my $rule_id = check_all_rule( $self, $mail_info );

	if ( $rule_id ){
		$self->{zlog}->log_match($rule_info, $mail_info), 
		return $self->{filterdb}->{$rule_id};
	}
	return undef;
}

sub load_filter_db
{
	my $self = shift;

	if ( defined $self->{filterdb} ) { return; }
	
	$self->{filterdb} = $self->{conf}->get_filter_db();

	# �õ��� rule_id Ϊ key �ı�
	$self->{filterdb} = $self->{filterdb}->{'rule-add-modify'}->{rule};
}

sub check_all_rule
{
	my $self = shift;

	my $mail_info = shift;

	$self->load_filter_db();

	foreach my $rule_id ( keys %{$self->{filterdb}} ){
		next if ( ! $rule_id );
		if ( check_attachment_rule ( $self, $rule_id, $mail_info ) &&
				check_size_rule ( $self, $rule_id, $mail_info ) &&
				check_keyword_rule ( $self, $rule_id, $mail_info ) ){
			return $rule_id;
		}
	}	
	return undef;
}

sub check_attachment_rule
{
	my $self = shift;
	my ($rule_id,$mail_info) = @_;

	# û�и�������ƥ���κθ�������
	if ( ! $mail_info->{attachment} ) { return 0; }

	my $attachment_rule = $self->{filterdb}->{$rule_id}->{attachment};

	if ( 'HASH' ne ref $attachment_rule ){
		#����
		foreach my $sub_attachment_rule ( @{$attachment_rule} ){
			if ( ! check_single_attachment_rule ( $self, $sub_attachment_rule, $mail_info ) ){
				return 0;
			}
		}
		return 1;
	}

	return check_single_attachment_rule ( $self, $attachment_rule, $mail_info );
}

sub check_size_rule
{
	my $self = shift;
	my ($rule_id,$mail_info) = @_;

	my $size_rule = $self->{filterdb}->{$rule_id}->{size};

	if ( 'HASH' ne ref $size_rule ){
		#����
		foreach my $sub_size_rule ( @{$size_rule} ){
			if ( ! check_single_size_rule ( $self, $sub_size_rule, $mail_info ) ){
				return 0;
			}
		}
		return 1;
	}
	return check_single_size_rule ( $self, $size_rule, $mail_info );
}

sub check_keyword_rule
{
	my $self = shift;
	my ($rule_id,$mail_info) = @_;

	my $keyword_rule = $self->{filterdb}->{$rule_id}->{rule_keyword};

	if ( -1 != $#$keyword_rule ){
		#����
		foreach my $sub_keyword_rule ( @{$keyword_rule} ){
			if ( ! check_single_keyword_rule ( $self, $sub_keyword_rule, $mail_info ) ){
				return 0;
			}
		}
		return 1;
	}
	return check_single_keyword_rule( $self, $keyword_rule, $mail_info );

}

sub check_single_attachment_rule
{
	my $self = shift;
	my ( $rule, $mail_info ) = @_;

	my ( $match_filename, $match_filetype, $match_filesize );
	$match_filename = $rule->{filename};
	$match_filetype = $rule->{filetype};
	$match_filesize = $rule->{sizevalue};

	foreach my $filename ( keys %{$mail_info->{body}} ){
		if ( $mail_info->{body}->{$filename}->{nofilename} ){
			next;
		}
		my $typeclass = $mail_info->{body}->{$filename}->{typeclass};
		my $size = $mail_info->{body}->{$filename}->{size} || 0;

		if ( defined $match_filename && (lc($filename) ne lc($match_filename)) ){
			return 0;
		}
		if ( defined $match_filetype && ($typeclass != $match_filetype) ){
			return 0;
		}
		if ( defined $match_filesize ){
			if ( 0==check_size_value( $self, $size, $match_filesize ) ){
				return 0;
			}
		}
	}

	# got match!
	return 1;
} 

#
# bytes,[NUMBER-NUMBER]��0��ʾ��������
#
sub check_size_value
{
	my $self = shift;

	my ( $size, $match_size ) = @_;

	if ( defined $match_size && $match_size =~ /(\d+)\-(\d+)/ ){
		$size_low = $1;
		$size_high = $1;
	}elsif ( defined $match_filesize ){
		$self->{zlog}->log ( "error: cannot parse  SIZEVALUE: [$match_size] to number-number" );
		return 0;
	}


	if ( 0==$size_low && $size <= $size_high ){
		return 1;
	}
	if ( 0==$size_high && $size >= $size_low ){
		return 1;
	}
	if ( $size >= $size_low || $size <= $size_high ){
		return 1;
	}

	# got no match!
	return 0;
}

sub ip2int{
	my $self = shift;
        my $ip = shift ;

        return undef unless $ip ;

        $ip =~ /0*(\d+)\.0*(\d+)\.0*(\d+)\.0*(\d+)/ ;
        $ip[0] = $1 ; $ip[1] = $2 ; $ip[2] = $3 ; $ip[3] = $4 ;

        $ip[0] = 0 if( !$ip[0] ) ; $ip[1] = 0 if( !$ip[1] ) ;
        $ip[2] = 0 if( !$ip[2] ) ; $ip[3] = 0 if( !$ip[3] ) ;

        ($ip[0] << 24) + ($ip[1]<<16) + ($ip[2]<<8) + $ip[3] ;
}

#
#	1 һ�������IP���磺"202.116.12.34"
# 	2 �ü���"-"��������IPֵ����ʾһ��������IP�Σ����������ϵ㣩���磺"202.116.22.1-202.116.22.24"
#	3 ��б��"/"�ָ���һ��IPֵ��һ�����֡��磺"202.116.22.0/24"��ʾ202.116.22.*
#
sub check_ip_range
{
	my $self = shift;

	my ( $ip, $ip_range ) = @_;

	if ( !defined $ip_range ){ 
		$self->{zlog}->log ( "error: check_ip_range no range found!" );
		return 0;
	}

	if ( $ip_range =~ /(\d+\.\d+\.\d+\.\d+)/ ){
		#	1 һ�������IP���磺"202.116.12.34"
		return ( $ip == $1 );
	}elsif ( $ip_range =~ /(\d+\.\d+\.\d+\.\d+)\-(\d+\.\d+\.\d+\.\d+)/ ){
		# 	2 �ü���"-"��������IPֵ����ʾһ��������IP�Σ����������ϵ㣩���磺"202.116.22.1-202.116.22.24"
		my ( $ip_start, $ip_end ) = ( $1, $2 );

		my ( $ip_long, $start_long, $end_long );
		$ip_long = ip2int($ip);
		$start_long = ip2int($ip_start);
		$end_long = ip2int($ip_end);

		return ( ($ip_long >= $start_long) && ($ip_long <= $end_long) );
	}elsif ( $ip_range =~ /(\d+\.\d+\.\d+\.\d+)\/(\d+)/ ){
		#	3 ��б��"/"�ָ���һ��IPֵ��һ�����֡��磺"202.116.22.0/24"��ʾ202.116.22.*
		my $bits = $2;
		my $match_long = ip2int($1);
		my $ip_long = ip2int($ip);

		$match_long = $match_long >> $bits;
		$ip_long = $ip_long >> $bits;

		return ( $ip_long == $match_long );
	}

	$self->{zlog}->log ( "error: check_ip_range got invalid ip range: [$ip_range]" );
	# got no match!
	return 0;
}
	
sub check_single_size_rule
{
	my $self = shift;
	my ( $rule, $mail_info ) = @_;

	my ( $match_key, $match_size );

	$match_key = $rule->{key};
	$match_size = $rule->{sizevalue};

	if ( ! $match_key || ! $match_size ){
		$self->{zlog}->log ( "error: cannot find SIZE KEY & SIZEVALUE: [$match_size]" );
		return 0;
	}

	if ( 1==$match_key ){ # ȫ�Ĵ�С
		my $mail_size;
		$mail_size = $mail_info->{body_size} + $mail_info{head_size};
		return ( check_size_value( $slef, $mail_size, $match_size ) );
	}elsif ( 2==$match_key ){ # ��ͷ
		return ( check_size_value( $self, $mail_info->{head_size}, $match_size ) );
	}elsif ( 3==$match_key ){ # ����
		return ( check_size_value( $self, $mail_info->{body_size}, $match_size ) );
	}elsif ( 4==$match_key ){ # ����
		return ( check_size_value( $self, $mail_info->{attachment_size}, $match_size ) );
	}elsif ( 5==$match_key ){ # ��������
		return ( check_size_value( $self, $mail_info->{attachment_num}, $match_size ) );
	}
	
	$self->{zlog}->log ( "error: unimplement size key: [$match_key]" );
	return 0;
} 

sub check_re_match
{
	my $self = shift;
	my ( $content, $re, $is_re ) = @_;

	if ( ! defined $re || ! defined $is_re ){
		$self->{zlog}->log ( "error: check_regex not enough param." );
		return 0;
	}

	if ( $is_re ){
		return ( $content=~/$re/ );
	}
	# XXX �ַ���ģ��ƥ��Ҳ������
	return ( $content=~/$re/ );
		
}

sub check_single_keyword_rule
{
	my $self = shift;
	my ( $rule, $mail_info ) = @_;

	my ( $match_key, $match_decode, $match_case_sensitive, $match_type, $match_keyword );
	$match_key = $rule->{key};
	$match_type = $rule->{type};
	$match_keyword = $rule->{keyword};

	if ( 1==$match_key ){ #1��������ؼ���
		return check_re_match ( $mail_info->{head}->{subject}, $match_keyword, $match_type );
	}elsif ( 2==$match_key ){ #2�����˰����ؼ���
		return check_re_match ( $mail_info->{head}->{from}, $match_keyword, $match_type );
	}elsif ( 3==$match_key ){ #3�ռ��˰����ؼ���
		return check_re_match ( $mail_info->{head}->{to}, $match_keyword, $match_type );
	}elsif ( 4==$match_key ){ #4�����˰����ؼ���
		return check_re_match ( $mail_info->{head}->{cc}, $match_keyword, $match_type );
	}elsif ( 5==$match_key ){ #5��ͷ�����ؼ���
		return check_re_match ( $mail_info->{head}->{content}, $match_keyword, $match_type );
	}elsif ( 6==$match_key ){ #6��������ؼ���
		return check_re_match ( $mail_info->{body_text}, $match_keyword, $match_type );
	}elsif ( 7==$match_key ){ #7ȫ�İ����ؼ���
		return ( check_re_match ( $mail_info->{body_text}, $match_keyword, $match_type ) &&
				check_re_match ( $mail_info->{head}->{content}, $match_keyword, $match_type ) );
	}elsif ( 8==$match_key ){ #8���������ؼ���
		#FIXME ��ǰ��ƥ���ļ�������������
		foreach my $filename ( keys %{$mail_info->{body}} ){
			if ( check_re_match ( $filename, $match_keyword, $match_type ) ){
				return 1;
			}
		}
		return 0;
	}elsif ( 9==$match_key ){ #9�ͻ���IPΪָ��ֵ����ָ����Χ��
		return check_ip_range( $self, $mail_info->{head}->{server_ip}, $match_keyword );
	}elsif ( 10==$match_key ){ #10Դ�ͻ���IP���ʼ��б�ʶ����ʼ��IP��ַ��Ϊָ��ֵ����ָ����Χ��
		return check_ip_range( $self, $mail_info->{head}->{sender_ip}, $match_keyword );
	}
	
	$self->{zlog}->log ( "error: check_single_keyword_rule find unknown key value [$match_key]." );

	return 0;
} 

#
#sub DESTROY
#{
#	# ɾ����ʱ�ļ�
#}

1;