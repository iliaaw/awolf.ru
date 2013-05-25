---
title: flask-uwsgi-nginx
verbose: Деплоймент Flask + uWSGI + nginx
date: 2012-08-16T13:21:00+04:00
tags: flask, uwsgi, nginx, python
---

Flask — это веб-фреймворк на Python, который отлично подходит для написания небольших проектов. Для запуска приложений на нем я использую связку uWSGI с nginx. На офсайте Flask есть руководство, посвященное uWSGI, но оно хреновое — зачем руками стартовать приложение, когда можно написать для него конфиг, который будет подхватываться при рестарте.

Руководство проверено для Flask 0.8, uWSGI 1.0.3, nginx 1.1.19.

Создаем `virtualenv` и ставим Flask.

~~~text
$ virtualenv env
$ source env/bin/activate
$ pip install flask
~~~

Ставим  uWSGI, nginx и плагин для Python для uWSGI. Под Debian я ставлю все из testing-репозитория.

~~~text
$ sudo apt-get install uwsgi nginx uwsgi-plugin-python
~~~

### nginx

Подробную настройку nginx оставим гуру этого дела, я ограничусь лишь основным. В `/etc/nginx/sites-available/` создаем новый конфиг, `flask.conf`, например, в нем пишем

~~~nginx
upstream flask_serv {
    server unix:/tmp/flask.sock;
}

server {
    listen 80;
    server_name <имя_сайта>;
    
    location / {
        uwsgi_pass flask_serv;
        include uwsgi_params;
    }

    location /static/ {
        root /путь/к/статике/;
    }
}
~~~

В `/etc/nginx/sites-enabled/` надо кинуть символическую ссылку на этот конфиг

~~~text
$ sudo ln -s /etc/nginx/sites-available/flask.conf 
/etc/nginx/sites-enabled/flask.conf
~~~

### uWSGI

Теперь в `/etc/uwsgi/apps-available/` создаем конфиг для uWSGI `flask.xml` следующего содержания

~~~xml
<uwsgi>
    <socket>/tmp/flask.sock</socket>
    <pythonpath>/путь/к/директории/с/приложением/</pythonpath>
    <module>app:app</module>
    <plugins>python27</plugins>
    <virtualenv>/путь/к/virtualenv/</virtualenv>
</uwsgi>
~~~

В `/etc/uwsgi/apps-enabled/` тоже надо создать символическую ссылку на конфиг

~~~text
$ sudo ln -s /etc/uwsgi/apps-available/flask.xml 
/etc/uwsgi/apps-enabled/flask.xml
~~~

Само приложение, соответственно, должно называться `app.py` и в минимальном виде может выглядеть примерно так:

~~~python
from flask import Flask
app = Flask(__name__)

@app.route("/")
def index():
    return "It works!"

if __name__ == "__main__":
    app.run()
~~~

На этом все, рестартуем nginx и uWSGI и радуемся жизни.
