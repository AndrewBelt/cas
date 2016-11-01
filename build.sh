#!/bin/sh

jade index.jade
coffee -cb main.coffee cas.coffee
stylus style.styl
jison parser.jison
