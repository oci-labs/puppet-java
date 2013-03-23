# NOTE: Make sure that node regexes do not overlap.

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