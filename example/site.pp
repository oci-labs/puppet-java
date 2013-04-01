import 'myNodes.pp'

class legacyJDK {
    class{ 'java':
        version => '1.7.0_07',
        tarfile =>  $::architecture ? {
            'amd64' => 'jdk-7u7-linux-x64.tar.gz',
            default => 'jdk-7u7-linux-i586.tar.gz',
        },
        force   => false
    }
}

class stableJDK {
    class{ 'java':
        version => '1.7.0_17',
        tarfile =>  $::architecture ? {
            'amd64' => 'jdk-7u17-linux-x64.tar.gz',
            default => 'jdk-7u17-linux-i586.tar.gz',
        },
        force   => false
    }
}

class stableJRE {
    class{ 'java':
        version => '1.7.0_17',
        tarfile =>  $::architecture ? {
            'amd64' => 'jre-7u17-linux-x64.tar.gz',
            default => 'jre-7u17-linux-i586.tar.gz',
        },
        force   => false
    }
}

class earlyAccessJDK {
    class{ 'java':
        version => '1.8.0',
        tarfile => $::architecture ? {
            'amd64' => 'jdk-8-ea-bin-b79-linux-x64-28_feb_2013.tar.gz',
            default => 'jdk-8-ea-bin-b79-linux-i586-28_feb_2013.tar.gz',
        },
        force   => true
    }
}

