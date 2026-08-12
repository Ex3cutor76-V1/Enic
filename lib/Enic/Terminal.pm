package Enic::Terminal;

use strict;
use warnings;

use File::Basename qw(dirname);
use Cwd qw(abs_path);

use Glib::Object::Introspection;

Glib::Object::Introspection->setup(
    basename => 'Vte',
    version  => '2.91',
    package  => 'Vte',
);

Glib::Object::Introspection->setup(
    basename => 'Pango',
    version  => '1.0',
    package  => 'Pango',
);

sub new {
    my ($class) = @_;

    my $terminal = Vte::Terminal->new();

    # ========================================================
    # Scrollback
    # ========================================================

    $terminal->set_scrollback_lines(2500);

    # ========================================================
    # Aparência do terminal
    # ========================================================

    my $fonte = Pango::FontDescription::from_string(
        'IBM Plex Mono 11'
    );

    $terminal->set_font($fonte);

    my $preto = Gtk3::Gdk::RGBA->new(
        0.0, 0.0, 0.0, 1.0
    );

    my $branco = Gtk3::Gdk::RGBA->new(
        1.0, 1.0, 1.0, 1.0
    );

    $terminal->set_colors(
        $branco,
        $preto,
        []
    );

    $terminal->set_cursor_blink_mode('on');
    $terminal->set_cursor_shape('block');

    # ========================================================
    # Atalhos do terminal
    # ========================================================

    $terminal->signal_connect(
        'key-press-event',
        sub {
            my ($widget, $event) = @_;

            my $key   = Gtk3::Gdk::keyval_name($event->keyval);
            my $state = $event->state;

            my $ctrl  = $state & ['control-mask'];
            my $shift = $state & ['shift-mask'];

            # ------------------------------------------------
            # Ctrl + Shift + V
            # ------------------------------------------------

            if (
                $ctrl &&
                $shift &&
                defined $key &&
                $key eq 'V'
            ) {
                $widget->paste_clipboard();

                return 1;
            }

            # ------------------------------------------------
            # Ctrl + Shift + C
            # ------------------------------------------------

            if (
                $ctrl &&
                $shift &&
                defined $key &&
                $key eq 'C'
            ) {
                $widget->copy_clipboard();

                return 1;
            }

            return 0;
        }
    );

    return bless {
        widget => $terminal,
    }, $class;
}

sub widget {
    my ($self) = @_;

    return $self->{widget};
}

sub iniciar_bash {
    my ($self) = @_;

    my $terminal = $self->{widget};

    # ========================================================
    # Localiza o diretório raiz do Enic
    #
    # Terminal.pm:
    #   Enic/Terminal.pm
    #
    # Projeto:
    #   ../../enic_prompt.bash
    # ========================================================

    my $arquivo_modulo = abs_path(__FILE__);

    die "Não foi possível localizar Terminal.pm\n"
        unless defined $arquivo_modulo;

    my $diretorio_enic = dirname(
        dirname(
            dirname($arquivo_modulo)
        )
    );

    my $prompt = "$diretorio_enic/enic_prompt.bash";

    die "Arquivo de prompt não encontrado: $prompt\n"
        unless -f $prompt;

    # ========================================================
    # Inicia o Bash
    # ========================================================

    $terminal->spawn_sync(
        'default',
        $ENV{HOME},
        [
            'bash',
            '--noprofile',
            '--rcfile',
            $prompt,
            '-i'
        ],
        [],
        'default',
        undef,
        undef,
    );

    return 1;
}

1;
