package Enic::Terminal;

use strict;
use warnings;

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

# Cache das familias instaladas: evita reler o fontconfig a cada split.
my %FAMILIAS_PANGO;

sub new {
    my ($class, $config) = @_;

    my $terminal = Vte::Terminal->new();

    # Scrollback definido pelo usuário
    $terminal->set_scrollback_lines($config->get('scrollback'));

    # Fonte definida pelo usuário, com familia verificada no Pango
    my $fonte = _resolver_fonte($terminal, $config->get('font'));

    $terminal->set_font($fonte);

    # Cor de fundo definida pelo usuário
    my $fundo = _rgba_from_hex($config->get('background'));

    # Define o texto como branco
    my $branco = Gtk3::Gdk::RGBA->new(
        1.0, 1.0, 1.0, 1.0
    );

    # Define cores do terminal
    $terminal->set_colors(
        $branco,
        $fundo,
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
        config => $config,
    }, $class;
}

# Familias de fonte conhecidas pelo Pango, consultadas uma unica vez.
sub _familias_disponiveis {
    my ($terminal) = @_;

    unless (%FAMILIAS_PANGO) {
        my $retorno = $terminal->get_pango_context()
            ->get_font_map()
            ->list_families();

        %FAMILIAS_PANGO = map { lc($_->get_name()) => 1 } @$retorno;
    }

    return \%FAMILIAS_PANGO;
}

# Verifica se a familia da fonte existe antes de aplicar.
sub _resolver_fonte {
    my ($terminal, $valor) = @_;

    my $fonte   = Pango::FontDescription::from_string($valor);
    my $familia = lc($fonte->get_family());
    my $disponiveis = _familias_disponiveis($terminal);

    unless ($disponiveis->{$familia}) {
        warn "Enic: Fonte '$valor' não encontrada. Usando padrão.\n";
        $fonte = Pango::FontDescription::from_string('IBM Plex Mono 11');
    }

    return $fonte;
}

# Converte '#RRGGBB' para os quatro componentes usados por Gdk::RGBA
sub _rgba_from_hex {
    my ($hex) = @_;

    my ($r, $g, $b) = $hex =~ /^#([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})$/;

    return Gtk3::Gdk::RGBA->new(
        hex($r) / 255,
        hex($g) / 255,
        hex($b) / 255,
        1.0,
    );
}

sub widget {
    my ($self) = @_;

    return $self->{widget};
}

sub iniciar_bash {
    my ($self) = @_;

    my $terminal = $self->{widget};
    my $shell = $self->{config}->get('shell');

    # Inicia o shell configurado em modo interativo
    # Sem --rcfile: respeita os arquivos de inicialização do usuário
    $terminal->spawn_sync(
        'default',
        $ENV{HOME},
        [
            $shell,
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
