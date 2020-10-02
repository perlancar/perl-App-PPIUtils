package App::PPIUtils;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use File::Slurper::Dash 'read_text';
use Sort::Sub;

our %SPEC;

our %arg0_filename = (
    filename => {
        summary => 'Path to Perl script/module',
        schema => 'filename*',
        default => '-',
        pos => 0,
    },
);

our %arg0_filenames = (
    filenames => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'filename',
        summary => 'Paths to Perl scripts/modules',
        schema => ['array*', of=>'filename*'],
        pos => 0,
        default => ['-'],
        slurpy => 1,
    },
);

sub _sort {
    my ($doc, $sorter, $sorter_meta) = @_;

    my @children = @{ $doc->{children} // [] };
    return unless @children;

    require Sort::SubList;
    my @sorted_children =
        map { $children[$_] }
        Sort::SubList::sort_sublist(
            sub {
                if ($sorter_meta->{compares_record}) {
                    my $rec0 = [$children[$_[0]]->name, $_[0]];
                    my $rec1 = [$children[$_[1]]->name, $_[1]];
                    $sorter->($rec0, $rec1);
                } else {
                    #say "D: ", $children[$_[0]]->name, " vs ", $children[$_[1]]->name;
                    $sorter->($children[$_[0]]->name, $children[$_[1]]->name);
                }
            },
            sub { $children[$_]->isa('PPI::Statement::Sub') && $children[$_]->name },
            0..$#children);
    $doc->{children} = \@sorted_children;
}

$Sort::Sub::argsopt_sortsub{sort_sub}{cmdline_aliases} = {S=>{}};
$Sort::Sub::argsopt_sortsub{sort_args}{cmdline_aliases} = {A=>{}};

$SPEC{sort_perl_subs} = {
    v => 1.1,
    summary => 'Sort Perl named subroutines by their name',
    description => <<'_',

This utility sorts Perl subroutine definitions in source code. By default it
sorts asciibetically. For example this source:

    sub one {
       ...
    }

    sub two { ... }

    sub three {}

After the sort, it will become:

    sub one {
       ...
    }

    sub three {}

    sub two { ... }

Caveat: if you intersperse POD documentation, currently it will not be moved
along with the subroutines.

_
    args => {
        %arg0_filename,
        %Sort::Sub::argsopt_sortsub,
    },
    result_naked => 1,
};
sub sort_perl_subs {
    require PPI::Document;

    my %args = @_;

    my $sortsub_routine = $args{sort_sub} // 'asciibetically';
    my $sortsub_args    = $args{sort_args} // {};

    my $doc = PPI::Document->new($args{filename});
    my ($sorter, $sorter_meta) =
        Sort::Sub::get_sorter($sortsub_routine, $sortsub_args, 'with meta');
    _sort($doc, $sorter, $sorter_meta);
    "$doc";
}

$SPEC{reverse_perl_subs} = {
    v => 1.1,
    summary => 'Reverse Perl subroutines',
    args => {
        %arg0_filename,
    },
    result_naked => 1,
};
sub reverse_perl_subs {
    my %args = @_;
    sort_perl_subs(%args, sort_sub=>'record_by_reverse_order');
}

1;
# ABSTRACT: Command-line utilities related to PPI

=head1 SYNOPSIS

This distribution provides the following command-line utilities related to
L<PPI>:

#INSERT_EXECS_LIST


=head1 append:SEE ALSO

L<PPI>

=cut
