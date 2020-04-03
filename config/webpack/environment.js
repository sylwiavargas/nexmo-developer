const webpack = require('webpack')
const { environment } = require('@rails/webpacker')
const jquery = require('./plugins/jquery')
const { VueLoaderPlugin } = require('vue-loader')
const vue = require('./loaders/vue')

const babelLoader = environment.loaders.get('babel')
babelLoader.exclude = []
environment.splitChunks()

environment.plugins.prepend('VueLoaderPlugin', new VueLoaderPlugin())
environment.loaders.prepend('vue', vue)

environment.loaders.get('sass').use.splice(-1, 0, {
  loader: 'resolve-url-loader',
});

environment.plugins.prepend('jquery', jquery)
module.exports = environment
