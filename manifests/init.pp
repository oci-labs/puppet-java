# Class: java
#
#   This module manages specific versions of java
#
#   Nathan Tippy <tippyn@ociweb.com>
#   2013-03-23
#
#   Tested platforms:
#    - Mint 13
#    - Ubuntu 12.04
#
# Parameters:
#   Java version to be installed, must match folder name inside tar
#   $version = '1.7.0_17'
#
#   Name of the tar file, must be already downloaded from oracle.
#   $tarfile = 'jdk-7u17-linux-x64.tar.gz'
#
#   Expand the tar even if its already installed.  This is needed for the
#   early access releases which will share the same folder name. (Optional)
#   $force = false
#
# Actions:
#
#  Installs and configures with update-alternatives the default java version.
#
# Requires:
#   The tar.gz files must be downloaded from oracle
#   and put into the java/files folder.
#   Be sure the $version number matches the contents of the tar file.
#   Be sure the names of the tar files clearly indicate jre or jdk
#
# Sample Usage:
#    case $name {
#        stableJRE: {
#            $version = '1.7.0_17'
#            $tarfile = $architecture ? {
#                    "amd64" => "jre-7u17-linux-x64.tar.gz",
#                    default => "jre-7u17-linux-i586.tar.gz",
#            }
#            $force = false
#        }
#        stableJDK: {
#            $version = '1.7.0_17'
#            $tarfile = $architecture ? {
#                "amd64" => "jdk-7u17-linux-x64.tar.gz",
#                default => "jdk-7u17-linux-i586.tar.gz",
#            }
#            $force = false
#        }
#        earlyAccessJDK: {
#            $version = '1.8.0'
#            $tarfile = $architecture ? {
#                "amd64" => "jdk-8-ea-bin-b79-linux-x64-28_feb_2013.tar.gz",
#                default => "jdk-8-ea-bin-b79-linux-i586-28_feb_2013.tar.gz",
#            }
#            $force = true
#        }
#        default: {
#            $version = '1.7.0_7'
#            $tarfile = $architecture ? {
#                    "amd64" => "jre-7u7-linux-x64.tar.gz",
#                    default => "jre-7u7-linux-i586.tar.gz",
#            }
#            $force = false
#        }
#    }
#    class{ 'java':
#        version => $version,
#        tarfile => $tarfile,
#        force => $force
#    }
class java($version, $tarfile, $force=false) {

    $jrebins = 'java,javaws,keytool,orbd,pack200,rmiregistry,servertool,tnameserv,unpack200'

    $jdk1bins = 'appletviewer,apt,extcheck,idlj,jar,jarsigner,javac,javadoc'
    $jdk2bins = 'javah,javap,jconsole,jdb,jhat,jinfo,jmap,jps,jrunscript'
    $jdk3bins = 'jsadebugd,jstack,jstat,jstatd,native2ascii,policytool,rmic'
    $jdk4bins = 'rmid,schemagen,serialver,wsgen,wsimport,xjc'
    $jdkbins =  "${jdk1bins},${jdk2bins},${jdk3bins},${jdk4bins}"
                        
    #do not set alernate compiler if there is no compiler
    if jre in $tarfile {
        $type = 'jre'
        $bins = "${jrebins}"
        
        file { "/tmp/${tarfile}":
            ensure => file,
            source => "puppet:///modules/java/${tarfile}",
        }
    } elsif jdk in $tarfile {
        $type = 'jdk'
        $bins = "${jrebins},${jdkbins}"
        
        file { "/tmp/${tarfile}":
            ensure => file,
            source => "puppet:///modules/java/${tarfile}",
        }
    } else {
        alert('ensure the tar file name contains substring jre or jdk')
    }

    if $::osfamily != 'Debian' {
        alert("This module only tested with Debian osfamily but ${::osfamily} was detected, use at your own risk.")
    }

    #Ensure that the directory for jvm exists
    file { '/usr/lib/jvm':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
    }

    if $force == true {
        file { "/usr/lib/jvm/${type}${version}" :
            ensure => absent,
            force  => true,
            before => Exec["untar-java-${type}${version}"],
        }
    }

    #untar new java distros into the right version folder
    #only if the base folder exists and triggered by file copy completion

    exec { "untar-java-${type}${version}":
        command   => "/bin/tar -xvzf /tmp/${tarfile}",
        cwd       => '/usr/lib/jvm',
        user      => 'root',
        creates   => "/usr/lib/jvm/${type}${version}",
        require   => File['/usr/lib/jvm'],
        subscribe => File["/tmp/${tarfile}"],
    }

    $versionarray = split($version, '[.]')
    $jvmfolder = "/usr/lib/jvm/java-${versionarray[1]}-oracle"

    #after new untar add a major version symlink
    file { $jvmfolder:
        ensure    => link,
        force     => true,
        target    => "/usr/lib/jvm/${type}${version}",
        subscribe => Exec["untar-java-${type}${version}"],
    }

    #install and set java javac javaws to this version of java

    $binsarray = split($bins, '[,]')
    altinstall{ $binsarray:
        jvmfolder => $jvmfolder
    }
}

#   using define to create 3 sets of execs
#   to update the alternatives for these bins
define altinstall ($jvmfolder) {

    #install this alternative only after the sim link is created

    exec { "alt-install-${name}":
        command   => "/usr/sbin/update-alternatives --install \"/usr/bin/${name}\" \"${name}\" \"${jvmfolder}/bin/${name}\" 1",
        subscribe => File[$jvmfolder],
    }

    #set this version as the active default after it is installed

    exec { "alt-set-${name}":
        command   => "/usr/sbin/update-alternatives --set \"${name}\" \"${jvmfolder}/bin/${name}\"",
        subscribe => Exec["alt-install-${name}"]
    }
}
