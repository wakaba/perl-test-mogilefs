package test::Test::MogileFS::Client;
use strict;
use warnings;
use base qw(Test::Class);
use Path::Class;
use File::Temp;
use lib file(__FILE__)->dir->parent->subdir('lib')->stringify;
use Test::MoreMore;
use Test::MogileFS::Client;

sub _no_use_mogilefs_client : Test(1) {
    eval q{
        use MogileFS::Client;
        ng 1;
    } or do {
        ok 1;
    };
}

sub _mogilefs_client : Test(5) {
    Test::MogileFS::Client->set_test_root_directory;
    ok my $client = Test::MogileFS::Client->new;
    my $key = time . rand();
    my $tmp_file = File::Temp->new;
    my $body = 'hello\n';
    print $tmp_file $body;
    close $tmp_file;
    ok $client->try_store_file($key, $tmp_file->filename);
    is_deeply $client->get_file_data($key), \$body;
    lives_ok { $client->delete($key) };
    is_deeply $client->get_file_data($key), undef;
}

__PACKAGE__->runtests;

1;
