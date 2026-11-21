package Enic::Config;

use strict;
use warnings;

use File::Spec;
use File::Path qw(make_path);

sub new {
    my ($class) = @_;

    my %defaults = (
        font       => 'IBM Plex Mono 11',
        shell      => '/bin/bash',
        scrollback => 2500,
        background => '#000000',
    );

    my $home = $ENV{HOME} || '.';

    my $base_dir = $ENV{XDG_CONFIG_HOME}
        || File::Spec->catdir($home, '.config');

    # Um XDG_CONFIG_HOME relativo precisa ser ancorado no diretorio atual
    $base_dir = File::Spec->rel2abs($base_dir);

    my $config_dir = File::Spec->catdir(
        $base_dir,
        'enic'
    );

    my $config_file = File::Spec->catfile(
        $config_dir,
        'enic.conf'
    );

    # Cria o diretório de configuração
    unless (-d $config_dir) {
        make_path($config_dir)
            or die "Enic: Não foi possível criar $config_dir\n";
    }

    # Cria o arquivo de configuração padrão
    unless (-e $config_file) {
        open my $file, '>', $config_file
            or die "Enic: Não foi possível criar $config_file: $!\n";

        print $file <<'EOF';
# Enic Configuration

font=IBM Plex Mono 11
shell=/bin/bash
scrollback=2500
background=#000000
EOF

        close $file
            or die "Enic: Erro ao salvar configuração: $!\n";
    }

    my %config = %defaults;

    # Lê as configurações
    open my $file, '<', $config_file
        or die "Enic: Não foi possível ler $config_file: $!\n";

    while (my $line = <$file>) {
        chomp $line;
        $line =~ s/^\s+|\s+$//g;

        next if $line eq '';
        next if $line =~ /^#/;

        next unless $line =~ /^([a-z_]+)\s*=\s*(.*?)\s*$/;

        my ($key, $value) = ($1, $2);

        if (exists $config{$key}) {
            $config{$key} = $value;
        } else {
            warn "Enic: Chave desconhecida '$key' em $config_file. Ignorada.\n";
        }
    }

    close $file;

    # Validação da fonte
    if ($config{font} eq '') {
        warn "Enic: Fonte inválida. Usando padrão.\n";
        $config{font} = $defaults{font};
    }

    # Validação do shell
    unless (-f $config{shell} && -x $config{shell}) {
        warn "Enic: Shell inválido. Usando padrão.\n";
        $config{shell} = $defaults{shell};
    }

    # Validação do scrollback
    unless ($config{scrollback} =~ /^\d+$/ && $config{scrollback} <= 9000) {
        warn "Enic: Scrollback inválido (máximo 9000). Usando padrão.\n";
        $config{scrollback} = $defaults{scrollback};
    }
    $config{scrollback} = int($config{scrollback});

    # Validação da cor de fundo
    unless ($config{background} =~ /^#[0-9a-fA-F]{6}$/) {
        warn "Enic: Cor inválida. Usando padrão.\n";
        $config{background} = $defaults{background};
    }

    return bless {
        settings => \%config,
        path     => $config_file,
    }, $class;
}

sub get {
    my ($self, $key) = @_;

    return $self->{settings}{$key};
}

sub path {
    my ($self) = @_;

    return $self->{path};
}

1;
