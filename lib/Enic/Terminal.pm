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

# Scrollback configurado para 2500
    $terminal->set_scrollback_lines(2500);

# Define a fonte do terminal
    my $fonte = Pango::FontDescription::from_string(
        'IBM Plex Mono 11'
    );

    $terminal->set_font($fonte);

# Determina o fundo como preto
    my $preto = Gtk3::Gdk::RGBA->new(
        0.0, 0.0, 0.0, 1.0
    );

# Define o texto como branco
    my $branco = Gtk3::Gdk::RGBA->new(
        1.0, 1.0, 1.0, 1.0
    );

# Define cores do terminal
    $terminal->set_colors(
        $branco,
        $preto,
        []
    );

# Cursor para piscar e ter formato de bloco
    $terminal->set_cursor_blink_mode('on');
    $terminal->set_cursor_shape('block');

# Atalhos de teclado
    $terminal->signal_connect(
        'key-press-event',
        sub {
            my ($widget, $event) = @_;

            my $key   = Gtk3::Gdk::keyval_name($event->keyval);
            my $state = $event->state;

            my $ctrl  = $state & ['control-mask'];
            my $shift = $state & ['shift-mask'];

# Verifica se CTRL + SHIFT + V foi pressionado
            if (
                $ctrl &&
                $shift &&
                defined $key &&
                $key eq 'V'
            ) {
# Cola o conteúdo copiado
                $widget->paste_clipboard();

                return 1;
            }

# Verifica se CTRL + SHIFT + C foi pressionado
            if (
                $ctrl &&
                $shift &&
                defined $key &&
                $key eq 'C'
            ) {
# Copia conteúdo selecionado
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

# Localiza o diretório raiz do Enic
# E obtém o caminho absoluto deste arquivo
# E sobe três níveis de diretório
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

# Inicia o bash interativo dentro do terminal VTE
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
