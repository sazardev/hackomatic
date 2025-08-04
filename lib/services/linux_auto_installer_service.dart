import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:developer' as dev;

/// Gestor de instaladores automáticos para herramientas específicas
/// Enfoque en simplicidad y automatización completa
class LinuxAutoInstallerService {
  static final LinuxAutoInstallerService _instance =
      LinuxAutoInstallerService._internal();
  factory LinuxAutoInstallerService() => _instance;
  LinuxAutoInstallerService._internal();

  final Map<String, bool> _installerStatus = {};
  final Map<String, List<String>> _installSteps = {};

  /// Instalar herramientas esenciales de Kali Linux en cualquier distribución
  Future<bool> installKaliTools() async {
    try {
      if (!Platform.isLinux) return false;

      _installSteps['kali'] = [];
      _installSteps['kali']!.add(
        '🐉 Iniciando instalación de herramientas Kali...',
      );

      // 1. Detectar package manager
      final packageManager = await _detectPackageManager();
      _installSteps['kali']!.add(
        '✅ Package manager detectado: $packageManager',
      );

      // 2. Actualizar repositorios
      await _updateRepositories(packageManager);
      _installSteps['kali']!.add('✅ Repositorios actualizados');

      // 3. Instalar herramientas por categoría
      await _installNetworkingTools(packageManager);
      _installSteps['kali']!.add('✅ Herramientas de red instaladas');

      await _installWebTools(packageManager);
      _installSteps['kali']!.add('✅ Herramientas web instaladas');

      await _installWirelessTools(packageManager);
      _installSteps['kali']!.add('✅ Herramientas wireless instaladas');

      await _installPasswordTools(packageManager);
      _installSteps['kali']!.add('✅ Herramientas de passwords instaladas');

      await _installForensicsTools(packageManager);
      _installSteps['kali']!.add('✅ Herramientas forenses instaladas');

      // 4. Configurar permisos especiales
      await _configureSpecialPermissions();
      _installSteps['kali']!.add('✅ Permisos configurados');

      // 5. Descargar wordlists
      await _downloadWordlists();
      _installSteps['kali']!.add('✅ Wordlists descargadas');

      _installerStatus['kali'] = true;
      _installSteps['kali']!.add('🎉 ¡Instalación de Kali Tools completada!');

      return true;
    } catch (e) {
      _installSteps['kali']?.add('❌ Error: $e');
      _installerStatus['kali'] = false;
      return false;
    }
  }

  /// Detectar package manager disponible
  Future<String> _detectPackageManager() async {
    final managers = ['apt', 'dnf', 'yum', 'pacman', 'zypper'];

    for (final manager in managers) {
      try {
        final result = await Process.run('which', [manager]);
        if (result.exitCode == 0) {
          return manager;
        }
      } catch (e) {
        continue;
      }
    }
    return 'unknown';
  }

  /// Actualizar repositorios
  Future<void> _updateRepositories(String packageManager) async {
    final commands = {
      'apt': ['apt', 'update'],
      'dnf': ['dnf', 'check-update'],
      'yum': ['yum', 'check-update'],
      'pacman': ['pacman', '-Sy'],
      'zypper': ['zypper', 'refresh'],
    };

    if (commands.containsKey(packageManager)) {
      await Process.run('sudo', commands[packageManager]!);
    }
  }

  /// Instalar herramientas de red
  Future<void> _installNetworkingTools(String packageManager) async {
    final tools = {
      'apt': [
        'nmap',
        'masscan',
        'zmap',
        'unicornscan',
        'netcat-traditional',
        'socat',
        'netdiscover',
        'arp-scan',
        'fping',
        'hping3',
        'tcpdump',
        'wireshark',
        'tshark',
        'ettercap-text-only',
      ],
      'dnf': ['nmap', 'netcat', 'tcpdump', 'wireshark', 'hping3'],
      'pacman': [
        'nmap',
        'masscan',
        'gnu-netcat',
        'tcpdump',
        'wireshark-qt',
        'hping',
      ],
    };

    await _installToolGroup(packageManager, tools[packageManager] ?? []);
  }

  /// Instalar herramientas web
  Future<void> _installWebTools(String packageManager) async {
    final tools = {
      'apt': [
        'nikto',
        'dirb',
        'gobuster',
        'ffuf',
        'wfuzz',
        'sqlmap',
        'commix',
        'xsser',
        'whatweb',
        'wafw00f',
        'sublist3r',
        'fierce',
      ],
      'dnf': ['nikto', 'sqlmap', 'whatweb'],
      'pacman': ['nikto', 'sqlmap', 'gobuster', 'ffuf'],
    };

    await _installToolGroup(packageManager, tools[packageManager] ?? []);
  }

  /// Instalar herramientas wireless
  Future<void> _installWirelessTools(String packageManager) async {
    final tools = {
      'apt': [
        'aircrack-ng',
        'reaver',
        'bully',
        'cowpatty',
        'kismet',
        'wifite',
        'hostapd',
        'dnsmasq',
      ],
      'dnf': ['aircrack-ng', 'kismet'],
      'pacman': ['aircrack-ng', 'kismet', 'hostapd', 'dnsmasq'],
    };

    await _installToolGroup(packageManager, tools[packageManager] ?? []);
  }

  /// Instalar herramientas de password cracking
  Future<void> _installPasswordTools(String packageManager) async {
    final tools = {
      'apt': [
        'john',
        'hashcat',
        'hydra',
        'medusa',
        'ncrack',
        'crunch',
        'cewl',
        'cupp',
        'patator',
      ],
      'dnf': ['john', 'hydra', 'hashcat'],
      'pacman': ['john', 'hashcat', 'hydra', 'medusa', 'crunch'],
    };

    await _installToolGroup(packageManager, tools[packageManager] ?? []);
  }

  /// Instalar herramientas forenses
  Future<void> _installForensicsTools(String packageManager) async {
    final tools = {
      'apt': [
        'binwalk',
        'foremost',
        'autopsy',
        'volatility',
        'sleuthkit',
        'dcfldd',
        'ddrescue',
        'testdisk',
      ],
      'dnf': ['binwalk', 'foremost', 'sleuthkit', 'testdisk'],
      'pacman': ['binwalk', 'foremost', 'sleuthkit', 'testdisk', 'ddrescue'],
    };

    await _installToolGroup(packageManager, tools[packageManager] ?? []);
  }

  /// Instalar grupo de herramientas
  Future<void> _installToolGroup(
    String packageManager,
    List<String> tools,
  ) async {
    for (final tool in tools) {
      try {
        final installCmd = _getInstallCommand(packageManager, tool);
        if (installCmd.isNotEmpty) {
          await Process.run('sudo', installCmd);
          if (kDebugMode) {
            dev.log('✅ $tool instalado');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          dev.log('❌ Error instalando $tool: $e');
        }
      }
    }
  }

  /// Obtener comando de instalación
  List<String> _getInstallCommand(String packageManager, String tool) {
    switch (packageManager) {
      case 'apt':
        return ['-c', 'apt install -y $tool'];
      case 'dnf':
        return ['-c', 'dnf install -y $tool'];
      case 'yum':
        return ['-c', 'yum install -y $tool'];
      case 'pacman':
        return ['-c', 'pacman -S --noconfirm $tool'];
      case 'zypper':
        return ['-c', 'zypper install -y $tool'];
      default:
        return [];
    }
  }

  /// Configurar permisos especiales
  Future<void> _configureSpecialPermissions() async {
    try {
      // Permitir captura de paquetes sin root
      await Process.run('sudo', [
        'setcap',
        'cap_net_raw,cap_net_admin=eip',
        '/usr/bin/dumpcap',
      ]);

      // Configurar grupos para el usuario
      final user = Platform.environment['USER'] ?? 'user';
      final groups = ['wireshark', 'dialout', 'plugdev'];

      for (final group in groups) {
        try {
          await Process.run('sudo', ['usermod', '-a', '-G', group, user]);
        } catch (e) {
          // Grupo puede no existir
        }
      }

      // Configurar sudoers para herramientas específicas
      await _configureSudoers(user);
    } catch (e) {
      if (kDebugMode) {
        dev.log('Error configurando permisos: $e');
      }
    }
  }

  /// Configurar sudoers para ejecución sin password
  Future<void> _configureSudoers(String user) async {
    final sudoersRules =
        '''
# Hackomatic sudoers rules
$user ALL=(ALL) NOPASSWD: /usr/bin/airmon-ng
$user ALL=(ALL) NOPASSWD: /usr/bin/airodump-ng
$user ALL=(ALL) NOPASSWD: /usr/bin/aireplay-ng
$user ALL=(ALL) NOPASSWD: /usr/bin/tcpdump
$user ALL=(ALL) NOPASSWD: /usr/sbin/ettercap
$user ALL=(ALL) NOPASSWD: /usr/bin/nmap
$user ALL=(ALL) NOPASSWD: /usr/bin/masscan
''';

    try {
      final tempFile = File('/tmp/hackomatic-sudoers');
      await tempFile.writeAsString(sudoersRules);

      await Process.run('sudo', [
        'cp',
        '/tmp/hackomatic-sudoers',
        '/etc/sudoers.d/hackomatic',
      ]);

      await Process.run('sudo', ['chmod', '0440', '/etc/sudoers.d/hackomatic']);

      await tempFile.delete();
    } catch (e) {
      if (kDebugMode) {
        dev.log('Error configurando sudoers: $e');
      }
    }
  }

  /// Descargar wordlists populares
  Future<void> _downloadWordlists() async {
    try {
      final homeDir = Platform.environment['HOME'] ?? '/home/user';
      final wordlistsDir = Directory('$homeDir/.hackomatic/wordlists');

      if (!await wordlistsDir.exists()) {
        await wordlistsDir.create(recursive: true);
      }

      // Descargar SecLists (contiene rockyou.txt y más)
      await _downloadSecLists(wordlistsDir.path);

      // Copiar wordlists del sistema si existen
      await _copySystemWordlists(wordlistsDir.path);
    } catch (e) {
      if (kDebugMode) {
        dev.log('Error descargando wordlists: $e');
      }
    }
  }

  /// Descargar SecLists
  Future<void> _downloadSecLists(String wordlistsDir) async {
    try {
      final secListsDir = Directory('$wordlistsDir/SecLists');

      if (!await secListsDir.exists()) {
        await Process.run('git', [
          'clone',
          'https://github.com/danielmiessler/SecLists.git',
          secListsDir.path,
        ]);
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('Error descargando SecLists: $e');
      }
    }
  }

  /// Copiar wordlists del sistema
  Future<void> _copySystemWordlists(String wordlistsDir) async {
    final systemPaths = [
      '/usr/share/wordlists',
      '/usr/share/dirb/wordlists',
      '/usr/share/dirbuster/wordlists',
      '/usr/share/wfuzz/wordlist',
    ];

    for (final systemPath in systemPaths) {
      final dir = Directory(systemPath);
      if (await dir.exists()) {
        try {
          await Process.run('cp', ['-r', systemPath, '$wordlistsDir/']);
        } catch (e) {
          // Continuar con el siguiente
        }
      }
    }
  }

  /// Instalar Metasploit Framework
  Future<bool> installMetasploit() async {
    try {
      _installSteps['metasploit'] = [];
      _installSteps['metasploit']!.add('🚀 Instalando Metasploit Framework...');

      // Método 1: Desde repositorios
      try {
        await Process.run('sudo', [
          '-c',
          'apt update && apt install -y metasploit-framework',
        ]);
        _installSteps['metasploit']!.add(
          '✅ Metasploit instalado desde repositorios',
        );
        _installerStatus['metasploit'] = true;
        return true;
      } catch (e) {
        _installSteps['metasploit']!.add(
          '⚠️ Instalación desde repos falló, intentando script oficial...',
        );
      }

      // Método 2: Script oficial de Rapid7
      final scriptPath = '/tmp/msfinstall';
      await Process.run('curl', [
        'https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb',
        '-o',
        scriptPath,
      ]);

      await Process.run('chmod', ['+x', scriptPath]);
      await Process.run('sudo', [scriptPath]);

      _installSteps['metasploit']!.add(
        '✅ Metasploit instalado con script oficial',
      );
      _installerStatus['metasploit'] = true;
      return true;
    } catch (e) {
      _installSteps['metasploit']?.add('❌ Error instalando Metasploit: $e');
      _installerStatus['metasploit'] = false;
      return false;
    }
  }

  /// Instalar Burp Suite Community
  Future<bool> installBurpSuite() async {
    try {
      _installSteps['burp'] = [];
      _installSteps['burp']!.add('🕷️ Instalando Burp Suite Community...');

      // Intentar via snap primero
      try {
        await Process.run('sudo', ['snap', 'install', 'burpsuite-community']);
        _installSteps['burp']!.add('✅ Burp Suite instalado via snap');
        _installerStatus['burp'] = true;
        return true;
      } catch (e) {
        _installSteps['burp']!.add(
          '⚠️ Snap no disponible, descargando desde PortSwigger...',
        );
      }

      // Descargar desde PortSwigger
      final homeDir = Platform.environment['HOME'] ?? '/home/user';
      final downloadPath = '$homeDir/.hackomatic/tools';
      final downloadDir = Directory(downloadPath);

      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // Nota: Burp Suite requiere instalación manual desde su sitio web
      _installSteps['burp']!.add(
        '📝 Burp Suite requiere descarga manual desde:',
      );
      _installSteps['burp']!.add(
        '   https://portswigger.net/burp/communitydownload',
      );
      _installSteps['burp']!.add(
        '💡 Se creó directorio en $downloadPath para herramientas',
      );

      _installerStatus['burp'] = false; // Requiere acción manual
      return false;
    } catch (e) {
      _installSteps['burp']?.add('❌ Error: $e');
      _installerStatus['burp'] = false;
      return false;
    }
  }

  /// Instalar Docker y contenedores de seguridad
  Future<bool> installDockerSecurityTools() async {
    try {
      _installSteps['docker'] = [];
      _installSteps['docker']!.add(
        '🐳 Instalando Docker y herramientas de seguridad...',
      );

      // Instalar Docker
      await Process.run('sudo', [
        '-c',
        'apt update && apt install -y docker.io docker-compose',
      ]);
      await Process.run('sudo', ['systemctl', 'enable', 'docker']);
      await Process.run('sudo', ['systemctl', 'start', 'docker']);

      // Agregar usuario al grupo docker
      final user = Platform.environment['USER'] ?? 'user';
      await Process.run('sudo', ['usermod', '-aG', 'docker', user]);

      _installSteps['docker']!.add('✅ Docker instalado y configurado');

      // Instalar contenedores útiles
      final containers = [
        'owasp/zap2docker-stable',
        'kalilinux/kali-rolling',
        'vulnerables/web-dvwa',
        'citizenstig/dvwa',
      ];

      for (final container in containers) {
        try {
          await Process.run('sudo', ['docker', 'pull', container]);
          _installSteps['docker']!.add('✅ Contenedor $container descargado');
        } catch (e) {
          _installSteps['docker']!.add('⚠️ Error descargando $container');
        }
      }

      _installerStatus['docker'] = true;
      _installSteps['docker']!.add('🎉 Docker y contenedores instalados');
      return true;
    } catch (e) {
      _installSteps['docker']?.add('❌ Error: $e');
      _installerStatus['docker'] = false;
      return false;
    }
  }

  /// Configurar entorno de desarrollo para exploits
  Future<bool> setupExploitDevelopment() async {
    try {
      _installSteps['exploit-dev'] = [];
      _installSteps['exploit-dev']!.add(
        '💻 Configurando entorno de desarrollo de exploits...',
      );

      // Instalar herramientas de desarrollo
      final devTools = [
        'build-essential',
        'gdb',
        'gdb-multiarch',
        'gcc-multilib',
        'python3-dev',
        'python3-pip',
        'ruby-dev',
        'nodejs',
        'npm',
      ];

      await _installToolGroup('apt', devTools);
      _installSteps['exploit-dev']!.add(
        '✅ Herramientas de desarrollo instaladas',
      );

      // Instalar herramientas Python para exploiting
      final pythonTools = [
        'pwntools',
        'ropper',
        'capstone',
        'keystone-engine',
        'unicorn',
        'angr',
        'z3-solver',
        'requests',
        'scapy',
      ];

      for (final tool in pythonTools) {
        try {
          await Process.run('pip3', ['install', tool]);
          _installSteps['exploit-dev']!.add('✅ $tool instalado');
        } catch (e) {
          _installSteps['exploit-dev']!.add('⚠️ Error instalando $tool');
        }
      }

      // Configurar GDB con plugins útiles
      await _setupGdbPlugins();
      _installSteps['exploit-dev']!.add('✅ GDB configurado con plugins');

      _installerStatus['exploit-dev'] = true;
      return true;
    } catch (e) {
      _installSteps['exploit-dev']?.add('❌ Error: $e');
      _installerStatus['exploit-dev'] = false;
      return false;
    }
  }

  /// Configurar plugins de GDB
  Future<void> _setupGdbPlugins() async {
    try {
      final homeDir = Platform.environment['HOME'] ?? '/home/user';
      final gdbInitFile = File('$homeDir/.gdbinit');

      final gdbConfig = '''
# Hackomatic GDB Configuration
set disassembly-flavor intel
set pagination off
set confirm off

# PEDA
source ~/peda/peda.py

# GEF (alternativa a PEDA)
# source ~/.gdbinit-gef.py

# Aliases útiles
define hook-run
python
import subprocess
import sys
try:
    subprocess.check_call(['clear'])
except:
    pass
end
end
''';

      await gdbInitFile.writeAsString(gdbConfig);

      // Descargar PEDA
      await Process.run('git', [
        'clone',
        'https://github.com/longld/peda.git',
        '$homeDir/peda',
      ]);
    } catch (e) {
      if (kDebugMode) {
        dev.log('Error configurando GDB: $e');
      }
    }
  }

  /// Obtener estado de los instaladores
  Map<String, bool> getInstallerStatus() => Map.from(_installerStatus);

  /// Obtener pasos de instalación
  Map<String, List<String>> getInstallSteps() => Map.from(_installSteps);

  /// Limpiar caché y archivos temporales
  Future<void> cleanup() async {
    try {
      await Process.run('sudo', ['apt', 'autoremove', '-y']);
      await Process.run('sudo', ['apt', 'autoclean']);

      // Limpiar archivos temporales de Hackomatic
      final tempFiles = ['/tmp/msfinstall', '/tmp/hackomatic-sudoers'];
      for (final file in tempFiles) {
        try {
          await File(file).delete();
        } catch (e) {
          // Archivo puede no existir
        }
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('Error en cleanup: $e');
      }
    }
  }
}
