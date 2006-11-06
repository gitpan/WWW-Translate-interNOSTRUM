package WWW::Translate::interNOSTRUM;

use strict;
use warnings;
use WWW::Mechanize;
use Carp qw(carp croak);

our $VERSION = '0.01';


my %lang_pairs = (
                    'ca-es' => 'Catalan -> Spanish',   # default
                    'es-ca' => 'Spanish -> Catalan',
                    'es-va' => 'Spanish -> Catalan with Valencian forms',
                 );

my %output =     (
                    plain_text => 'txtf',  # default
                    marked_text => 'txt',
                 );

my %defaults =   (
                    lang_pair => 'ca-es',
                    output => 'plain_text',
                 );

my @fields = ('agent', keys %defaults);


sub new {
    my $class = shift;
    
    # validate overrides
    my %overrides = @_;
    foreach (keys %overrides) {
        # Invalid key
        carp "Unknown parameter: $_\n" unless exists $defaults{$_};
        # Invalid value
        if ($_ eq 'output' && !exists $output{$overrides{output}}) {
            my $message = "Invalid value for parameter 'output', " .
                          "$overrides{output}.\n" .
                          "Will use the default value instead.\n";
            carp ($message);
            delete $overrides{$_};
        }
        if ($_ eq 'lang_pair' && !exists $lang_pairs{$overrides{lang_pair}}) {
            my $message = "Invalid value for parameter 'lang_pair', " .
                          "$overrides{lang_pair}.\n" .
                          "Will use the default value instead.\n";
            carp ($message);
            delete $overrides{$_};
        }
    }
    
    my %args = (%defaults, %overrides);
    $args{agent} = WWW::Mechanize->new();
    
    # remove invalid parameters
    my %this;
    @this{@fields} = @args{@fields};
    
    return bless(\%this, $class);
}


sub translate {
    my $self = shift;
    
    my $string;
    if (@_ > 0) {
        $string = shift;
    } else {
        croak "There's nothing to translate\n";
    }
    
    return '' if ($string eq '');

    # interNOSTRUM url
    my $url = 'http://www.internostrum.com/welcome.php';
    
    my $mech = $self->{agent};
    
    $mech->get($url);
    croak $mech->response->status_line unless $mech->success;
    
    $mech->field("quadretext", $string);  
    
    if ($self->{lang_pair} eq 'es-va') {
        $self->{lang_pair} = 'es-ca';
        $mech->tick('valen', 1);
    }
    $mech->select("direccio", $self->{lang_pair});  
    
    $mech->select("tipus", $output{$self->{output}});
    
    $mech->click();
    
    my $response = $mech->content();
            
    my $translated;
    if ($response =~
        /spelling\.<\/div>\s*<p class="textonormal">(.+?)<\/p>/s) { 
            $translated = $1;
    }
            
    # remove double spaces
    $translated =~ s/(\S)\s{2}(\S)/$1 $2/g;
        
    return $translated;
    
}

sub from_into {
    my $self = shift;
    
    if (@_) {    
        my $pair = shift;
        $self->{lang_pair} = $pair if exists $lang_pairs{$pair};
    } else {
        return $self->{lang_pair};
    }
    
}

sub output_format {
    my $self = shift;
    
    if (@_) {
        my $format = shift;
        $self->{output} = $format if exists $output{$format};
    } else {
        return $self->{output};
    }
}


1;

__END__


=head1 NAME

WWW::Translate::interNOSTRUM - Catalan < > Spanish machine translation


=head1 VERSION

Version 0.01 November 6, 2006


=head1 SYNOPSIS

    use WWW::Translate::interNOSTRUM; 
    my $engine = WWW::Translate::interNOSTRUM->new();
    
    my $translated_string = $engine->translate($string);
    
    # default language pair is Catalan -> Spanish
    # change to Spanish -> Catalan:
    $engine->from_into('es-ca');
    
    # check current language pair:
    my $current_langpair = $engine->from_into();
    
    # default output format is 'plain_text'
    # change to 'marked_text':
    $engine->output_format('marked_text');
    
    # check current output format:
    my $current_format = $engine->output_format();
    

=head1 DESCRIPTION

interNOSTRUM is a Catalan < > Spanish machine translation engine developed by
the Department of Software and Computing Systems of the University of Alicante
in Spain. This module provides an OO interface to the interNOSTRUM engine
web server.

interNOSTRUM provides approximate translations of Catalan into Spanish and
Spanish into Catalan. It generates both the central variant of Oriental
Catalan (the standard variant used in Catalonia) and, optionally,
Valencian forms, which follow the recommendations published in the guide
L<http://www.ua.es/spv/assessorament/criteris.pdf>.
For more information on the Catalan variants, please see the References
below.


=head1 CONSTRUCTOR

=head2 new()

Creates and returns a new WWW::Translate::interNOSTRUM object.

    my $engine = WWW::Translate::interNOSTRUM->new();
    

WWW::Translate::interNOSTRUM recognizes the following parameters:

=over 4

=item * C<< lang_pair >>

The valid values of this parameter are:

=over 8

=item * C<< es-ca >>

Spanish into Standard Catalan

=item * C<< es-va >>

Spanish into Valencian

=item * C<< ca-es >>

Standard Catalan or Valencian into Spanish

=back

Default value: 'ca-es'.


=item * C<< output >>

The valid values of this parameter are:

=over 8

=item * C<< plain_text >>

Returns the translation as plain text.

=item * C<< marked_text >>

Returns the translation with the unknown words marked with an asterisk.

=back

Default value: 'plain_text'

=back


The default parameter values can be overridden when creating a new
interNOSTRUM engine object:

    my %options = (
                    lang_pair => 'es-ca',
                    output => 'marked_text',
                  );
    my $engine = WWW::Translate::interNOSTRUM->new(%options);

                                                    

=head1 METHODS

=head2 $engine->translate($string)

Returns the translation of $string generated by interNOSTRUM.
$string must be a string of ANSI text, and can contain up to 16,384 characters.
If the encoding of the source text isn't Latin-1, you must convert it to Latin-1
before sending it to the MT engine. You can use the Encode module for this task.


=head2 $engine->from_into($lang_pair)

Changes the engine language pair to $lang_pair.
When called with no argument, it returns the value of the current engine
language pair:

    $current_langpair = $engine->from_into();


=head2 $engine->output_format($format)

Changes the engine output format to $format.
When called with no argument, it returns the value of the current engine
output format:

    $current_format = $engine->output_format();


=head1 DEPENDENCIES

WWW::Mechanize 1.20 or higher.


=head1 REFERENCES

interNOSTRUM website:

L<http://www.internostrum.com/welcome.php>

Department of Software and Computing Systems (University of Alicante):

L<http://www.dlsi.ua.es/index.cgi?id=eng>

For more information on the variants of Catalan, see:

L<http://en.wikipedia.org/wiki/Catalan_language>


=head1 ACKNOWLEDGEMENTS

Many thanks to Mikel Forcada Zubizarreta, coordinator of the interNOSTRUM
project, who kindly answered my questions during the development of this module.


=head1 AUTHOR

Enrique Nell, E<lt>perl_nell@telefonica.netE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Enrique Nell.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut



