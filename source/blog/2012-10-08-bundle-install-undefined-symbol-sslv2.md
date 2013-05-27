---
title: bundle-install-undefined-symbol-sslv2
verbose: Undefined symbol SSLv2_method while running bundle install
tags: ruby, ubuntu, linux
date: 2012-10-08T19:20:00+04:00
---

If you get an error message `undefined symbol: SSLv2_method` after running `bundle install` inside Rails project's dir and if you use RVM on Ubuntu, here is a solution to this problem. Note that it's better to take care of this problem before installing Ruby. Otherwise, you have to reinstall Ruby later.

Everything in the Ruby world changes quite quickly, so it's better to know the exact versions of software I used while testing this solution.

* Ruby `1.9.3-p194`
* RVM `1.15.8 (stable)`

Activate RVM if you haven't already done that.

~~~text
$ source ~/.rvm/scripts/rvm
~~~

Install openssl library that has SSLv2 support.

~~~text
$ rvm pkg install openssl
~~~

Install Ruby specifying the path to the openssl library. If you have already installed Ruby, replace `"install"` with `"reinstall"`.

~~~text
$ rvm install 1.9.3 --with-openssl-dir=$rvm_path/usr
~~~

And that's it. Now you can install gems.

~~~text
$ bundle install
~~~
