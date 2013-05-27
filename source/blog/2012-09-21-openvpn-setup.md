---
title: openvpn-setup
verbose: Настройка OpenVPN для выхода в интернет
date: 2012-09-21T20:18:00+04:00
tags: vpn, openvpn, linux, ubuntu
---

Полезно иметь под рукой VPN, настроенный для выхода через него в интернет. Мне, например, он нужен для того, чтобы спокойно лазить в инет через открытые WiFi-точки, не боясь за свои пароли (в 2012 году все еще есть сайты, которые не используют HTTPS).

### Настройка сервера (Ubuntu)

Устанавливаем OpenVPN из репозитория.

~~~text
$ sudo apt-get install openvpn
~~~

Генерируем сертификаты и ключи (которые надо держать в секрете). Нам понадобятся:

* Сертификаты для сервера и для каждого клиента, а также приватные ключи для них.
* CA-сертификат `ca.crt` и ключ `ca.key` для подписи сертификатов сервера и клиентов.
* Ключ Diffie Hellman. Нужен для установления защищенного соединения.

В составе OpenVPN есть утилита для генерации ключей, которая лежит в `/usr/share/doc/openvpn/examples/easy-rsa/2.0/`. В файле `vars` можно поменять настройки под себя, можно оставить дефолтные.

Инициализация (обращаем внимание на то, что после первой точки есть пробел):

~~~text
$ . ./vars
$ ./clean-all
~~~

Генерируем `ca.crt` и `ca.key`, сертификаты и ключи для сервера/клиентов и ключ Diffie Hellman. На вопросы можно не отвечать и просто давить `Enter`.

~~~text
$ ./build-ca 
$ ./build-key-server server_name
$ ./build-key client_name1
$ ./build-key client_name2
$ ./build-dh
~~~

Копируем нужные на сервере файлы в `/etc/openvpn/`.

~~~text
$ cp ./keys/ca.crt /etc/openvpn/
$ cp ./keys/server_name.crt /etc/openvpn/
$ cp ./keys/server_name.key /etc/openvpn/
$ cp ./keys/dh1024.pem /etc/openvpn/
~~~

Ключ `ca.key` используется только для подписи сертификатов --- поэтому его можно не держать в `/etc/openvpn/`, но обязательно нужно сохранить в надежном месте и никому не показывать.

Разбираемся с конфигом. В `/usr/share/doc/openvpn/examples/sample-config-files/` есть шаблон `server.conf`, в нем подробно прокомментированы все опции. Мой конфиг выглядит примерно так:

~~~text
port 1194                       # дефолтный порт
proto upd                       # используемый протокол
dev tun                         # "dev tun" --- для IP-туннеля
ca ca.crt                       # CA-сертификат
cert server_name.crt            # сертификат сервера
key server_name.key             # приватный ключ сервера
dh dh1024.pem                   # ключ Diffie Hellman
server 10.8.0.0 255.255.255.0   # используемая подсеть
ifconfig-pool-persist ipp.txt   # файл с адресами клиентов
push "redirect-gateway"         # перенаправлять весь трафик через VPN
keepalive 10 120                # пинговать каждые 10 сек, 
                                # если нет ответа 120 сек --- отваливаться
comp-lzo                        # использовать сжатие
user nobody                     # на всякий случай даем как можно меньше прав
group nogroup
persist-key                     # не перечитывать ключи
persist-tun                     # не переоткрывать tun-device
log-append /var/log/openvpn.log # лог-файл
verb 4                          # уровень детализации лога
~~~

Прописываем правила `iptables`. Нужно разрешить клиентам из подсети `10.8.0.0/24` доступ в интернет, разрешить принимать пакеты из интернета и пропустить трафик клиентов через NAT.

~~~text
iptables -A FORWARD -s 10.8.0.0/24 -j ACCEPT
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
~~~

Чтобы правила не сбросились после перезагрузки, добавляем их в `/etc/rc.local`.

Включаем форвардинг в ядре: в `/etc/sysctl.conf` добавляем (или раскомментируем) строку 

~~~text
net.ipv4.ip_forward=1
~~~

Чтобы форвардинг заработал без перезагрузки, делаем

~~~text
$ echo 1 > /proc/sys/net/ipv4/conf/all/forwarding
~~~

Если клиент уже находится за NAT-ом, проброс трафика не заработает, а в логах можно будет найти строки вроде `"MULTI: bad source address from client [a.b.c.d], packet dropped"` --- так как у OpenVPN нет правил для обработки пакетов из подсети `a.b.c.0/24`, они дропаются. Поэтому прописываем нужные правила: в `/etc/openvpn/server.conf` добавляем строки

~~~text
client-config-dir ccd           # директория с настройками для клиентов
route a.b.c.0 255.255.255.0     # обрабатывать пакеты из подсети a.b.c.0/24
~~~

а в `/etc/openvpn/ccd/` создаем файл `client_name1.conf` и в нем пишем

~~~text
iroute a.b.c.0 255.255.255.0    # разрешаем доступ к VPN из подсети a.b.c.0/24
~~~

Настройка серверной части закончена, перезапускаем OpenVPN.

~~~text
$ sudo service openvpn restart
~~~

### Настройка клиента (Ubuntu)

Во-первых, надо установить OpenVPN на клиенте.

~~~text
$ sudo apt-get install openvpn
~~~

Во-вторых, с сервера надо скопировать CA-сертификат `ca.crt`, сертификат `client_name1.crt` и ключ `client_name1.key`.

Есть два способа настройки клиентской части OpenVPN. Первый --- с использованием конфига в `/etc/openvpn/`. В `/usr/share/doc/openvpn/examples/sample-config-files/` есть шаблон `client.conf` с комментариями. Мой конфиг выглядит примерно так:

~~~text
client                          # указываем, что это клиент
dev tun                         # на сервере и клиенте должно совпадать
proto udp                       # на сервере и клиенте должно совпадать
remote a.b.c.d 1194             # адрес и порт сервера
resolv-retry infinite           # пытаться достучаться до сервера бесконечно
nobind                          # не использовать какой-то особый порт
user nobody                     # на всякий случай даем как можно меньше прав
group nogroup                   # на всякий случай даем как можно меньше прав
persist-key                     # не перечитывать ключи
persist-tun                     # не переоткрывать tun-device
mute-replay-warnings            # подавлять предупреждения о повторных пакетах
ca ca.crt                       # CA-сертификат
cert client_name1.crt           # сертификат клиента
key client_name1.key            # приватный ключ клиента
comp-lzo                        # на сервере и клиенте должно совпадать
log-append /var/log/openvpn.log # лог-файл
verb 4                          # уровень детализации лога
~~~

Второй способ --- настройка через GUI. Ставим плагин для network manager:

~~~text
$ sudo apt-get install network-manager-openvpn
~~~

И добавляем VPN в Network Connections (VPN Connections -> Configure VPN -> Add). Там все просто и понятно: нужно вбить адрес сервера и указать путь к `ca.crt` и клиентскому сертификату/ключу. Остальные настройки (протокол, порт, использовать ли сжатие, etc) тоже можно поменять.

Замечание насчет DNS: домены могут не резолвиться при перенаправлении трафика через VPN, если используются DNS-сервера провайдера, доступные только из его локальной сети. Поэтому лучше использовать какие-нибудь публичные DNS-сервера, например, Google Public DNS (`8.8.8.8` и `8.8.4.4`).