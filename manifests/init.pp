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
    # Takes 3 parameters and the third one has a default of false.
    # Variables in puppet can only be assigned once.
    # Here we build some simple strings we will need later.

    # These are all the binaries provided by the JRE.
    $jrebins = 'java,javaws,keytool,orbd,pack200,rmiregistry,servertool,tnameserv,unpack200'

    $jdk1bins = 'appletviewer,extcheck,idlj,jar,jarsigner,javac,javadoc'
    $jdk2bins = 'javah,javap,jconsole,jdb,jhat,jinfo,jmap,jps,jrunscript'
    $jdk3bins = 'jsadebugd,jstack,jstat,jstatd,native2ascii,policytool,rmic'
    $jdk4bins = 'rmid,schemagen,serialver,wsgen,wsimport,xjc'

    # Puppet does not have a concat operator for strings however it does have
    # interpolation when the " double quote is used. Making use of the
    # variables defined above a single large string is built.
    # These are all the binaries provided by the JDK.
    $jdkbins =  "${jdk1bins},${jdk2bins},${jdk3bins},${jdk4bins}"

    # If the string 'jre' or 'jdk' is found in the tar file name we set the
    # appropriate values for $type and $bins
    # The file copy operation from the master to this node is done only if its
    # recognized to be a jre or jdk. Further down in the exec for untar the
    # subscribe metaparameter is used to continue the install ONLY if this
    # file gets created:       subscribe => File["/tmp/${tarfile}"]
    if jre in $tarfile {
        $type = 'jre'
        $bins = $jrebins

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
        # File in temp folder is not created so the install stops.
    }

    # Warn users that this was only intended for Debian platforms but
    # the install will continue anyway
    if $::osfamily != 'Debian' {
        alert("This module only tested with Debian osfamily but ${::osfamily} was detected, use at your own risk.")
    }

    # Ensure that the directory for jvm exists
    # Require is used by the exec for untar below to ensure the right ordering.
    file { '/usr/lib/jvm':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
    }

    # The exec for untar uses the creates metaparameter to tell puppet not to
    # bother running the command again if the creates file exists.
    # When we need to change whats inside the tar we need to force it by
    # ensuring the expected folder name destination is absent.
    if $force == true {
        file { "/usr/lib/jvm/${type}${version}" :
            ensure => absent,
            force  => true,
            before => Exec["untar-java-${type}${version}"],
        }
    }

    # untar new Java distros into the right version named folder
    # Will not run if the creates=> folder already exists
    # Will not run if the require=> folder user/lib/jvn does not exist
    # Will not run if the subscribe=> file has not been created
    exec { "untar-java-${type}${version}":
        command   => "/bin/tar -xvzf /tmp/${tarfile}",
        cwd       => '/usr/lib/jvm',
        user      => 'root',
        creates   => "/usr/lib/jvm/${type}${version}",
        require   => File['/usr/lib/jvm'],
        subscribe => File["/tmp/${tarfile}"],
    }

    # Splits a string on the the dot token and creates array versionarray
    $versionarray = split($version, '[.]')
    $jvmfolder = "/usr/lib/jvm/java-${versionarray[1]}-oracle"


    # Subscribes to the exec for untar so if executed
    # it will then add a symlink to the version folder
    # force must be used just in case a symlink already exists but
    # it is pointing at some old location.
    file { $jvmfolder:
        ensure    => link,
        force     => true,
        target    => "/usr/lib/jvm/${type}${version}",
        subscribe => Exec["untar-java-${type}${version}"],
    }

    # Parse the string of binaries on the comma and produce an array
    $binsarray = split($bins, '[,]')

    # This call to the define works like a macro.
    # The $binsarray values are each mapped to $name causing multiple
    # exec commands to get called based on what is in the array.
    altinstall{ $binsarray:
        jvmfolder => $jvmfolder
    }
}

# Using define to create 3 sets of execs
# to update the alternatives for these bins
define altinstall ($jvmfolder) {

    # Install this alternative only if the sim link is created
    # the command its self requires double quotes but double quotes are also
    # in use by puppet because the string is interpolated. In order to make this
    # work the quotes needed by the command are escaped with \"
    exec { "alt-install-${name}":
        command     => "/usr/sbin/update-alternatives --install \"/usr/bin/${name}\" \"${name}\" \"${jvmfolder}/bin/${name}\" 1",
        subscribe   => File[$jvmfolder],
        path        => "/usr/bin",
        onlyif      => "test `/usr/sbin/update-alternatives --display ${name} |/bin/grep -c \"points to ${jvmfolder}/bin/${name}\"` -eq 0",
    }

    # Set this version as the active default if it is installed
    exec { "alt-set-${name}":
        command   => "/usr/sbin/update-alternatives --set \"${name}\" \"${jvmfolder}/bin/${name}\"",
        subscribe => Exec["alt-install-${name}"],
        path      => "/usr/bin",
        onlyif    => "test `/usr/sbin/update-alternatives --display ${name} |/bin/grep -c \"points to ${jvmfolder}/bin/${name}\"` -eq 0",
    }
}
