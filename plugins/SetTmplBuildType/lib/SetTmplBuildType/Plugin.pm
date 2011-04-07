package SetTmplBuildType::Plugin;
use strict;

sub _set_buildtype {
    my $app = shift;
    my @id = $app->param( 'id' ) or return $app->errtrans( 'Invalid request.' );
    my $user = $app->user;
    my $perms = $app->permissions;
    my $admin = $user->is_superuser
      || ( $perms && $perms->can_administer_blog );
    my $edit_templates = $admin
      || ( $perms
        && ( $perms->edit_templates ) )
      ? 1 : 0;
    if (! $edit_templates ) {
        return $app->trans_error( 'Permission denied.' );
    }
    my $action = $app->param( 'action_name' );
    my $setting = 0;
    if ( $action eq 'set2static' ) {
        $setting = 1;
    } elsif ( $action eq 'set2manually' ) {
        $setting = 2;
    } elsif ( $action eq 'set2dynamic' ) {
        $setting = 3;
    } elsif ( $action eq 'set2queue' ) {
        $setting = 4;
    }
    for my $id ( @id ) {
        my $tmpl = MT::Template->load( $id );
        next unless defined $tmpl;
        my $remove_archive;
        if ( $tmpl->type eq 'index' ) {
            my $old_type = $tmpl->build_type;
            my $new_type = $setting;
            if ( $old_type != $new_type ) {
                if ( my $blog = $tmpl->blog ) {
                    my $site_path = $blog->site_path || '';
                    require File::Spec;
                    my $outfile = $tmpl->outfile;
                    $remove_archive = File::Spec->catfile( $site_path, $outfile );
                }
            }
        }
        $tmpl->build_type( $setting );
        $tmpl->save or die $tmpl->errstr;
        if ( $remove_archive ) {
            require MT::FileMgr;
            my $fmgr = MT::FileMgr->new( 'Local' ) or die MT::FileMgr->errstr;
            if ( $fmgr->exists( $remove_archive ) ) {
                my $do = $fmgr->delete( $remove_archive );
                if ( $do != 1 ) {
                    MT->log( $do );
                }
            }
        }
    }
    $app->add_return_arg( saved => 1 );
    $app->call_return;
}

sub _list_template {
    my ( $cb, $app, $tmpl ) = @_;
    $$tmpl =~ s!(<form\sid="module-listing-form".*?)<option\svalue="set2static">.*?</option>!$1!s;
    $$tmpl =~ s!(<form\sid="system-listing-form".*?)<option\svalue="set2static">.*?</option>!$1!s;
    $$tmpl =~ s!(<form\sid="email-listing-form".*?)<option\svalue="set2static">.*?</option>!$1!s;
    $$tmpl =~ s!(<form\sid="module-listing-form".*?)<option\svalue="set2manually">.*?</option>!$1!s;
    $$tmpl =~ s!(<form\sid="system-listing-form".*?)<option\svalue="set2manually">.*?</option>!$1!s;
    $$tmpl =~ s!(<form\sid="email-listing-form".*?)<option\svalue="set2manually">.*?</option>!$1!s;
    $$tmpl =~ s!(<form\sid="module-listing-form".*?)<option\svalue="set2dynamic">.*?</option>!$1!s;
    $$tmpl =~ s!(<form\sid="system-listing-form".*?)<option\svalue="set2dynamic">.*?</option>!$1!s;
    $$tmpl =~ s!(<form\sid="email-listing-form".*?)<option\svalue="set2dynamic">.*?</option>!$1!s;
    $$tmpl =~ s!(<form\sid="module-listing-form".*?)<option\svalue="set2queue">.*?</option>!$1!s;
    $$tmpl =~ s!(<form\sid="system-listing-form".*?)<option\svalue="set2queue">.*?</option>!$1!s;
    $$tmpl =~ s!(<form\sid="email-listing-form".*?)<option\svalue="set2queue">.*?</option>!$1!s;
    $$tmpl =~ s!(<form\sid="module-listing-form".*?)<option\svalue="set2no_publish">.*?</option>!$1!s;
    $$tmpl =~ s!(<form\sid="system-listing-form".*?)<option\svalue="set2no_publish">.*?</option>!$1!s;
    $$tmpl =~ s!(<form\sid="email-listing-form".*?)<option\svalue="set2no_publish">.*?</option>!$1!s;
}

1;