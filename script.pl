#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';
use Enic::Terminal;

use IO::Select;
use POSIX qw(WNOHANG);

# ============================================================
# ENIC - Terminal Emulator
#
# Versão: 0.3
# ============================================================

# ============================================================
# Criação do objeto Terminal
# ============================================================

my $terminal = Enic::Terminal->new();

my $pty   = $terminal->{pty};
my $slave = $terminal->{slave};

# ============================================================
# Inicia o Bash
# ============================================================

my $pid = $terminal->start();

print "PID armazenado no objeto: ", $terminal->pid(), "\n";
# ============================================================
# Estado original do terminal físico.
# ============================================================

my $estado_terminal;

# ============================================================
# Função: preparar_terminal
# ============================================================

sub preparar_terminal {

    $estado_terminal = `stty -g`;

    chomp $estado_terminal;

    system("stty", "raw", "-echo")
        == 0
        or die "Não foi possível colocar o terminal em raw mode: $!\n";
}

# ============================================================
# Função: restaurar
# ============================================================

sub restaurar {

    return unless defined $estado_terminal;
    return if $estado_terminal eq '';

    system("stty", $estado_terminal);
}

# ============================================================
# Restauração automática do terminal físico.
# ============================================================

END {
    restaurar();
}

# ============================================================
# Copia o tamanho do terminal físico para o PTY.
# ============================================================

$terminal->resize(\*STDIN);

# ============================================================
# PROCESSO PAI
# ============================================================

print "Enic 0.3\n";
print "Bash iniciado (PID: $pid)\n";
print "Ctrl+D ou 'exit' para sair.\n\n";

# ============================================================
# Coloca o terminal físico em raw mode.
# ============================================================

preparar_terminal();

# ============================================================
# IO::Select
# ============================================================

my $selector = IO::Select->new();

$selector->add(\*STDIN);
$selector->add($pty);

my $stdin_fd = fileno(STDIN);
my $pty_fd   = fileno($pty);

# ============================================================
# Controle de resize
# ============================================================

my $resize_pendente = 0;

$SIG{WINCH} = sub {
    $resize_pendente = 1;
};

# ============================================================
# LOOP PRINCIPAL
# ============================================================

while (1) {

    my @ready = $selector->can_read();

    # ========================================================
    # Verifica se a janela foi redimensionada
    # ========================================================

    if ($resize_pendente) {

        $terminal->resize(\*STDIN);

        $resize_pendente = 0;
    }

    foreach my $fh (@ready) {

        my $fd = fileno($fh);

        # ====================================================
        # ENTRADA DO USUÁRIO
        # ====================================================

        if ($fd == $stdin_fd) {

            my $buffer;

            my $bytes = sysread(
                STDIN,
                $buffer,
                4096
            );

            # ------------------------------------------------
            # EOF
            # ------------------------------------------------

            if (!defined $bytes || $bytes == 0) {

                syswrite($pty, "exit\n");

                next;
            }

            # ------------------------------------------------
            # Envia exatamente os bytes recebidos para o PTY.
            # ------------------------------------------------

            my $enviados = 0;

            while ($enviados < $bytes) {

                my $resultado = syswrite(
                    $pty,
                    $buffer,
                    $bytes - $enviados,
                    $enviados
                );

                last unless defined $resultado;

                $enviados += $resultado;
            }
        }

        # ====================================================
        # SAÍDA DO BASH
        # ====================================================

        elsif ($fd == $pty_fd) {

            my $buffer;

            my $bytes = sysread(
                $pty,
                $buffer,
                4096
            );

            # ------------------------------------------------
            # Bash terminou.
            # ------------------------------------------------

            if (!defined $bytes || $bytes == 0) {
                last;
            }

            # ------------------------------------------------
            # Envia os bytes recebidos do Bash para a tela.
            # ------------------------------------------------

            my $enviados = 0;

            while ($enviados < $bytes) {

                my $resultado = syswrite(
                    STDOUT,
                    $buffer,
                    $bytes - $enviados,
                    $enviados
                );

                last unless defined $resultado;

                $enviados += $resultado;
            }
        }
    }

    # ========================================================
    # Verifica se o Bash terminou.
    # ========================================================

    my $resultado = waitpid($pid, WNOHANG);

    last if $resultado == $pid;
}

# ============================================================
# Limpeza
# ============================================================

$selector->remove(\*STDIN);

waitpid($pid, 0);

print "\nEnic encerrado.\n";
