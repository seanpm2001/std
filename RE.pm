
package main;
sub indent { my $s = shift;
    $s =~ s/^/\n  /mg;
    $s;
}

sub qm { my $s = shift;
    my $r = '';
    for (split(//,$s)) {
        if ($_ eq " ") { $r .= '\x20' }
        elsif ($_ eq "\t") { $r .= '\t' }
        elsif ($_ eq "\n") { $r .= '\n' }
        elsif ($_ =~ m/^\w$/) { $r .= $_ }
        elsif ($_ eq '<' | $_ eq '>') { $r .= $_ }
        else { $r .= '\\' . $_ }
    }
    $r;
}

sub here {
    return unless $DEBUG & DEBUG::longest_token_pattern_generation;
    my $arg = shift;
    my $lvl = 0;
    while (caller($lvl)) { $lvl++ }
    my ($package, $file, $line, $subname, $hasargs) = caller(0);

    my $name = $package;   # . '::' . substr($subname,1);
    if (defined $arg) { 
        $name .= " " . $arg;
    }
    ::deb("\t", ':' x $lvl, ' ', $name, " [", $file, ":", $line, "]") if $DEBUG & DEBUG::longest_token_pattern_generation;
}

{ package RE_base;
    sub longest { my $self = shift; my ($C) = @_;  ::here("UNIMPL @{[ref $self]}"); "$self" }
}

{ package RE; our @ISA = 'RE_base';
    sub longest { my $self = shift; my ($C) = @_; 
        ::here();
        local $ALT = '';
        $self->{'re'}->longest($C);
    }
}

{ package RE_adverb; our @ISA = 'RE_base';
    #method longest ($C) { ... }
}

{ package RE_assertion; our @ISA = 'RE_base';
    sub longest { my $self = shift; my ($C) = @_; 
        for (scalar($self->{'assert'})) { if ((0)) {}
            elsif ($_ eq '?') {
                my $re = $self->{'re'};
#               $C->deb("\n",::Dump($self)) unless $re;
                if (ref($re) eq 'RE_method_re' and $re->{'name'} eq 'before') {
                    my @result = $re->longest($C);
                    return map { $_ . $IMP } @result;
                }
            }
        }
        return '';
    }
}

{ package RE_assertvar; our @ISA = 'RE_base';
    sub longest { my $self = shift; my ($C) = @_; 
        return $IMP;
    }
}

{ package RE_block; our @ISA = 'RE_base';
    sub longest { my $self = shift; my ($C) = @_; 
        return '' if $PURIFY;
        return $IMP;
    }
}

{ package RE_bindvar; our @ISA = 'RE_base';
    sub longest { my $self = shift; my ($C) = @_; ::here();
        $self->{'atom'}->longest($C);
    }
}

{ package RE_bindnamed; our @ISA = 'RE_base';
    sub longest { my $self = shift; my ($C) = @_; ::here();
        $self->{'atom'}->longest($C);
    }
}

{ package RE_bindpos; our @ISA = 'RE_base';
    sub longest { my $self = shift; my ($C) = @_; ::here();
        $self->{'atom'}->longest($C);
    }
}

{ package RE_bracket; our @ISA = 'RE_base';
    sub longest { my $self = shift; my ($C) = @_; ::here();
        $self->{'re'}->longest($C);
    }
}

{ package RE_cclass; our @ISA = 'RE_base';
    sub longest { my $self = shift; my ($C) = @_; ::here($self->{'text'});
        $fakepos++;
        my $cc = $self->{'text'};
        Encode::_utf8_on($cc);
        $cc =~ s/^\-\[/[^/;
        $cc =~ s/^\+\[/[/;
        $cc =~ s/\s*\.\.\s*/-/g;
        $cc =~ s/\s*//g;
        $cc = "(?i:$cc)" if $self->{i};
        $cc;
    }
}

{ package RE_decl; our @ISA = 'RE_base';
    sub longest { my $self = shift; my ($C) = @_;  return; }
}

{ package RE_double; our @ISA = 'RE_base';
    # XXX inadequate for "\n" without interpolation
    sub longest { my $self = shift; my ($C) = @_; 
        my $text = $self->{'text'};
        Encode::_utf8_on($text);
        ::here($text);
        my $fixed = '';
        if ( $text =~ /^(.*?)[\$\@\%\&\{]/ ) {
            $fixed = $1 . $IMP;
        }
        else {
            $fixed = $text;
        }
        if ($fixed ne '') {
            $fakepos++;
            ::qm($fixed);
        }
        $fixed =~ s/([a-zA-Z])/'[' . $1 . chr(ord($1)^32) . ']'/eg if $self->{i};
        $fixed;
    }
}

{ package RE_meta; our @ISA = 'RE_base';
    sub longest { my $self = shift; my ($C) = @_; 
        my $text = $self->{'text'};
        Encode::_utf8_on($text);
        ::here($text);
        for (scalar($text)) { if ((0)) {}
            elsif ($_ eq '^' or
                   $_ eq '$' or
                   $_ eq '.' or
                   $_ eq '\\w' or
                   $_ eq '\\s' or
                   $_ eq '\\d')
            {
                return $text;
            }
            elsif ($_ eq '\\h') {
                return '[\\x20\\x09\\x0d]';
            }
            elsif ($_ eq '\\v') {
                return '[\\x0a\\x0c]';
            }
            elsif ($_ eq '\\N') {
                return '[^\\x0a]';
            }
            elsif ($_ eq '$$') {
                return '(?:\\x0a|$)';
            }
            elsif ($_ eq ':' or $_ eq '^^') {
                return;
            }
            elsif ($_ eq '»' or $_ eq '>>') {
                return '\b';
            }
            elsif ($_ eq '«' or $_ eq '<<') {
                return '\b';
            }
            elsif ($_ eq '::' or $_ eq ':::' or $_ eq '.*?') {
                return $IMP;
            }
            else {
                return $text;
            }
        }
    }
}

{ package RE_method; our @ISA = 'RE_base';
    sub longest { my $self = shift; my ($C) = @_; 
        my $name = $self->{'name'};
        return $IMP if $self->{'rest'};
        Encode::_utf8_on($name);
        ::here($name);
        for (scalar($name)) { if ((0)) {}
            elsif ($_ eq 'null') {
                return;
            }
            elsif ($_ eq '') {
                return $IMP;
            }
            elsif ($_ eq 'ws') {
                return $IMP;
            }
            elsif ($_ eq 'sym') {
                $fakepos++;
                my $sym = $self->{'sym'};
                Encode::_utf8_on($sym);
                my $text = ::qm($sym);
                $text =~ s/(\pL)/'[' . lc($1) . uc($1) . ']'/eg if $self->{i};
                return $text;
            }
            elsif ($_ eq 'ww') {
                return '\w' . $IMP;
            }
            elsif ($_ eq 'alpha') {
                $fakepos++;
                return '[_[:alpha:]\pL]';
            }
            my $lexer;
            {
                local $PREFIX = "";
                $name .= '__PEEK';
                $lexer = eval { $C->cursor_peek->$name() };
            }
            return $IMP unless $lexer and exists $lexer->{PATS};
            my @pat = @{$lexer->{PATS}};
            return unless @pat;
            if ($PREFIX) {
                for (@pat) {
                    s/(\t\(\?#FATE)\d* *(.*?\))(.*)/$3$1$PREFIX $2/g;
                }
            }
            return @pat;
        }
    }
}

{ package RE_method_internal; our @ISA = 'RE_base';
    sub longest { my $self = shift; my ($C) = @_; 
        return $IMP;
    }
}

{ package RE_method_re; our @ISA = 'RE_base';
    sub longest { my $self = shift; my ($C) = @_; 
        my $name = $self->{'name'};
        Encode::_utf8_on($name);
        ::here($name);
        my $re = $self->{'re'};
        for (scalar($name)) { if ((0)) {}
            elsif ($_ eq '') {
                return $IMP;
            }
            elsif ($_ eq 'after') {
                return;
            }
            elsif ($_ eq 'before') {
                my @result = $re->longest($C);
                return map { $_ . $IMP } @result;
            }
            else {
                $name .= '__PEEK';
                my $lexer = $C->cursor_peek->$name($re);
                my @pat = @{$lexer->{PATS}};
                return unless @pat;
                return @pat;
            }
        }
    }
}

{ package RE_noop; our @ISA = 'RE_base';
    sub longest { my $self = shift; my ($C) = @_; 
        return $IMP;
    }
}

{ package RE_every; our @ISA = 'RE_base';
    sub longest { my $self = shift; my ($C) = @_; 
        return $IMP;
    }
}

{ package RE_first; our @ISA = 'RE_base';
    sub longest { my $self = shift; my ($C) = @_; 
        my $alts = $self->{'zyg'};
        ::here(0+@$alts);
        my @result;
        for my $alt (@$alts) {
            my @pat = $alt->longest($C);
            push @result, @pat;
            last;
        }
        $C->deb(join("\n",@result)) if $DEBUG & DEBUG::longest_token_pattern_generation;
        @result;
    }
}

{ package RE_paren; our @ISA = 'RE_base';
    sub longest { my $self = shift; my ($C) = @_; ::here();
        $self->{'re'}->longest($C);
    }
}

{ package RE_quantified_atom; our @ISA = 'RE_base';
    sub longest { my $self = shift; my ($C) = @_; 
        ::here();
        my $oldfakepos = $fakepos++;
        my $a = $self->{atom};
        my @atom = $a->longest($C);
        return unless @atom;
        my $atom = join('|',@atom);
        return if $atom eq '';
        $atom = "(?:" . $atom . ')' unless $a->{min} == 1 and ref($a) =~ /^RE_(?:meta|cclass|string)/;
        if ($self->{'quant'}[0] eq '+') {
            if (@atom > 1) {
                return map { $_ . $IMP } @atom;
            }
            return "$atom+";
        }
        elsif ($self->{'quant'}[0] eq '*') {
            $fakepos = $oldfakepos;
            if (@atom > 1) {
                return map { $_ . $IMP } @atom,'';
            }
            return "$atom*";
        }
        elsif ($self->{'quant'}[0] eq '?') {
            $fakepos = $oldfakepos;
            if (@atom > 1) {
                return @atom,'';
            }
            return "$atom?";
        }
        elsif ($self->{'quant'}[0] eq '**') {
            my $x = $self->{'quant'}[2];
            if ($x =~ /^\d/) {
                $x =~ s/\.\./,/;
                $x =~ s/\*//;
                $fakepos = $oldfakepos if $x =~ m/^0/;
                return $atom . "{$x}";
            }
            else {
                return $atom . $IMP;
            }
        }
        return $IMP;
    }
}

{ package RE_qw; our @ISA = 'RE_base';
    sub longest { my $self = shift; my ($C) = @_; 
        my $text = $self->{'text'};
        Encode::_utf8_on($text);
        ::here($text);
        $fakepos++;
        $text =~ s/^<\s*//;
        $text =~ s/\s*>$//;
        $text =~ s/\s+/|/;
        '(?: ' . $text . ')';
    }
}

{ package RE_sequence; our @ISA = 'RE_base';
    sub longest { my $self = shift; my ($C) = @_; 
        my $result = [''];
        my $c = $self->{'zyg'};
        my @chunks = @$c;
        ::here(0+@chunks);
        local $PREFIX = $PREFIX;

        for my $chunk (@chunks) {
            # ignore negative lookahead
            next if ref($chunk) eq 'RE_assertion' and $chunk->{assert} eq '!';
            $C->deb("NULLABLE ".ref($chunk)) if $DEBUG & DEBUG::longest_token_pattern_generation and not $chunk->{min};
            my @newalts = $chunk->longest($C);
            last unless @newalts;
#           if (not $chunk->{min} and $next[-1] ne '') {
#               push(@next, '');        # install bypass around nullable atom
#           }
            my $newresult = [];
            my $pure = 0;
            for my $oldalt (@$result) {
                if ($oldalt =~ /\(\?#::\)/) {
                    push(@$newresult, $oldalt);
                    next;
                }

                for my $newalt (@newalts) {
                    $pure = 1 unless $newalt =~ /\(\?#::\)/;
#                   $PREFIX = '' if $newalt =~ /FATE/;;
                    if ($oldalt =~ /FATE/ and $newalt =~ /FATE/) {
                        my $newold = $oldalt;
                        my $newnew = $newalt;
                        $newnew =~ s/\t\(\?#FATE\d* *(.*?)\)//;
                        my $morefate = $1;
                        $newold =~ s/(FATE.*?)\)/$1 $morefate)/;
                        push(@$newresult, $newold . $newnew);
                    }
                    else {
                        push(@$newresult, $oldalt . $newalt);
                    }
                }
            }
            $result = $newresult;
            last unless $pure;  # at least one alternative was pure
            # ignore everything after positive lookahead
            last if ref($chunk) eq 'RE_assertion';
        }
        @$result;
    }
}

{ package RE_string; our @ISA = 'RE_base';
    sub longest { my $self = shift; my ($C) = @_; 
        my $text = $self->{'text'};
        Encode::_utf8_on($text);
        ::here($text);
        $fakepos++ if $self->{'min'};
        $text = ::qm($text);
        $text =~ s/([[:alpha:]])/'[' . $1 . chr(ord($1)^32) . ']'/eg if $self->{i};
        $text;
    }
}

{ package RE_submatch; our @ISA = 'RE_base';
    sub longest { my $self = shift; my ($C) = @_; 
        return $IMP;
    }
}

{ package RE_all; our @ISA = 'RE_base';
    sub longest { my $self = shift; my ($C) = @_; 
        return $IMP;
    }
}

{ package RE_any; our @ISA = 'RE_base';
    sub longest { my $self = shift; my ($C) = @_; 
        my $alts = $self->{'zyg'};
        ::here(0+@$alts);
        my @result;
        my $oldfakepos = $fakepos;
        my $minfakepos = $fakepos + 1;
        my $base = $ALT // '';
        $base .= ' ' if $base;
        my %autolexbase = %AUTOLEXED;
        for my $alt (@$alts) {
            local %AUTOLEXED = %autolexbase;    # alts are independent
            $fakepos = $oldfakepos;
            local $ALT = $base . $alt->{alt};
            {
                local $PREFIX = $PREFIX . ' ' . $ALT;
                my @pat = ($alt->longest($C));
                push @result, map { /#FATE/ or s/$/\t(?#FATE $PREFIX)/; $_ } @pat;
            }
            $minfakepos = $oldfakepos if $fakepos == $oldfakepos;
        }
        $C->deb(join("\n", @result)) if $DEBUG & DEBUG::longest_token_pattern_generation;
        $fakepos = $minfakepos;  # Did all branches advance?
        @result;
    }
}

{ package RE_var; our @ISA = 'RE_base';
    #method longest ($C) { ... }
    sub longest { my $self = shift; my ($C) = @_; 
        my $var = $self->{var};
        if (my $p = $C->_PARAMS) {
            my $text = $p->{$var} || return $IMP;
            $fakepos++ if length($text);
            $text = ::qm($text);
            return $text;
        }
        return $IMP;
    }
}

## vim: expandtab sw=4