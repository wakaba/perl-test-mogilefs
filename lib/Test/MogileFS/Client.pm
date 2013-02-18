package Test::MogileFS::Client;
use strict;
use warnings;
our $VERSION = '1.0';
use Test::MoreMore::Mock;
use File::Temp qw(tempdir);
use Carp;
use Path::Class;

our $DEBUG ||= $ENV{MOGILEFS_DEBUG};

sub disable_real_mogilefs {
    my $class = "MogileFS::Client";
    my $file = $class;
    $file =~ s[::][/]g;
    $file .= '.pm';
    if ($INC{$file} and $INC{$file} ne '1') {
        die "Module $class ($INC{$file}) has been loaded", Carp::longmess;
    }
    $INC{$file} = 1;
    no strict 'refs';
    *{$class . '::new'} = sub {
        die "An attempt is made to instantiate class $class", Carp::longmess;
    };
    *{$class . '::import'} = sub {
        die "An attempt is made to import class $class", Carp::longmess;
    };

    @Hatena::MogileFS::Client::ISA = qw(Test::MoreMore::Mock);
    $INC{'Hatena/MogileFS/Client.pm'} = 1;
}

BEGIN {
    __PACKAGE__->disable_real_mogilefs;
}

my $tmp_d = dir(tempdir);

our $ROOT_D = $tmp_d->subdir('mogilefs');

sub new {
    my $class = shift;
    return bless {@_}, $class;
}

sub set_test_root_directory {
    my $class = shift;
    $ROOT_D = $tmp_d->subdir('mogilefs')->subdir(time . rand);
    warn sprintf "MogileFS job directory: %s\n", $ROOT_D if $DEBUG;
}

sub get_f {
    my ($self, $mogile_key) = @_;
    my $f = $ROOT_D->file($mogile_key);
    my $d = $f->dir;
    $d->mkpath;
    return $f;
}

sub try_store_content {
    my ($self, $mogile_key, $data) = @_;

    my $f = $self->get_f($mogile_key);
    my $file = $f->openw;
    print $file $data;
}

sub try_store_file {
    my ($self, $mogile_key, $file_name) = @_;

    if (-f $file_name) {
        my $data = file($file_name)->slurp or do { warn "$file_name: $!"; return 0 };
        $self->try_store_content($mogile_key, $data);
        return 1;
    }

    return 0;
}

sub try_mirror {
    my ($self, $key, $path) = @_;
    system 'touch', $path;
}

sub get_file_data {
    my ($self, $mogile_key) = @_;

    my $f = $self->get_f($mogile_key);
    if (-f $f) {
        return \($f->slurp or die "$f: $!");
    } else {
        return undef;
    }
}

sub delete {
    my ($self, $mogile_key) = @_;
    my $f = $self->get_f($mogile_key);
    if (-f $f) {
        unlink $f;
    }
}

1;
