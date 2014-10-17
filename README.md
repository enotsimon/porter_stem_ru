porter_stem_ru
==============

erlang porter stemmer for russian language

implementation of original algorythm from

  http://snowball.tartarus.org/algorithms/russian/stemmer.html

install
=======

add this to your rebar.config

{porter_stem_ru, ".*", {git, "https://github.com/skorobogatko/porter_stem_ru.git", {branch, "master"}}}

or compile manually

use
===

porter_stem_ru:stem(AnySingleRussianWord)