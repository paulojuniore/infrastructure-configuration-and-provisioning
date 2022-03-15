node 'puppet1.domain.com.br' {
    package { 'httpd':
        ensure  => "installed",
    }
    service { 'httpd':
        ensure => running,
    enable => true
    }
}