puppet-java
===========

Manage JRE/JDK Java 7 or Java 8 on Ubuntu or Mint

background
---------

Staying ahead of zero-day exploits can be difficult especially when managing a large enterprise deployment.
This puppet module will help manage large groups of servers which may have different required versions of Java.

#### example situation
* I have 10 web servers that need the QA approved stable JDK7 release
* I have 3 tester/QA workstations that need the QA approved stable JRE7 release
* I have an experimental box that needs the latest early access JDK8 release
* The business has decided that we must upgrade to the next relese due to security concerns

#### solving the given situation
* [Download Java](http://www.oracle.com/technetwork/java/javase/downloads/index.html) tar.gz into etc/puppet/modules/java/files 
* Edit the filename and version number for this release of Java in the site.pp file
* Push updated site.pp to your puppet master
* Wait for client machines to update to the configured Java version (by default should happen within 30 minutes)

#### limitations
* At this time this module only works with Debian derived distos such as Ubuntu and Mint.
* Java is not distributed with this module, it must be downloaded from Oracle as needed.
* If a single puppet master is used to support 10's of clients deployment may be slowed due to network congestion.

setup
-----

It is highly recommended that all the files put under /etc/puppet are kept in SVN or GIT.
Check out from SVN/GIT should be used as the preferred way to update files on the puppet master.

#### deploy module
Put the /manifests and /files folders into the /etc/puppet/modules/java folder on the puppet master.

#### download Java
[Download](http://www.oracle.com/technetwork/java/javase/downloads/index.html) all the versions of Java to be supported in your organization.
If you run a mixed 32bit/64bit environment be sure to download both versions. 
All these files must be copied into the etc/puppet/modules/java/files on the puppet master.

#### update site.pp
Add a section similar to the one here to your site.pp file.
This class serves as a central place for defining the versions and Java files supported by your organization.

Upgrading Java versions is greatly simplified because this is the only place where changes need to be made.
When making changes be sure that the version number matches the version found inside the tar.gz file.

<pre>
import 'nodes.pp'

class myJavaVersion($name = legacyJDK) {
    case $name {
        stableJRE: {
            $version = '1.7.0_17'
            $tarfile = $::architecture ? {
                'amd64' => 'jre-7u17-linux-x64.tar.gz',
                default => 'jre-7u17-linux-i586.tar.gz',
            }
            $force = false
        }
        stableJDK: {
            $version = '1.7.0_17'
            $tarfile = $::architecture ? {
                'amd64' => 'jdk-7u17-linux-x64.tar.gz',
                default => 'jdk-7u17-linux-i586.tar.gz',
            }
            $force = false
        }
        earlyAccessJDK: {
            $version = '1.8.0'
            $tarfile = $::architecture ? {
                'amd64' => 'jdk-8-ea-bin-b79-linux-x64-28_feb_2013.tar.gz',
                default => 'jdk-8-ea-bin-b79-linux-i586-28_feb_2013.tar.gz',
            }
            $force = true
        }
        default: {
            $version = '1.7.0_7'
            $tarfile = $::architecture ? {
                'amd64' => 'jdk-7u7-linux-x64.tar.gz',
                default => 'jdk-7u7-linux-i586.tar.gz',
            }
            $force = false
        }
    }
    class{ 'java':
        version => $version,
        tarfile => $tarfile,
        force   => $force
    }
}
</pre>

#### update nodes.pp
In your nodes.pp file you can then do something like the simple example here.

Be careful that any regular expressions used to define nodes do not overlap. 
If they do, the first definition matching the fully qualified name will be applied and this may lead to unexpected behavior.

<pre>
node basenode {
    #include any common modules that need to be everywhere
    #some examples might be vim, hosts file, etc.
}

#   this will match www<number>.ociweb.com
node /^www\d+\.ociweb\.com$/ inherits basenode {
    include myJavaVersion(legacyJDK)
}

#   this will match qa<number>.ociweb.com
node /^qa\d+\.ociweb\.com$/ inherits basenode {
    include myJavaVersion(stableJRE)
}

#   this will match dev<number>.ociweb.com
node /^dev\d+\.ociweb\.com$/ inherits basenode {
    include myJavaVersion(stableJDK)
}

node 'experimental.ociweb.com' inherits basenode {
    include myJavaVersion(earlyAccessJDK)
}
</pre>

