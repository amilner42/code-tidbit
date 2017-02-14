var path = require("path");
var ExtractTextPlugin = require("extract-text-webpack-plugin");
var CopyWebpackPlugin = require('copy-webpack-plugin');


module.exports = {
  entry: {
    app: [
      './src/index.js'
    ]
  },

  output: {
    path: path.resolve(__dirname + '/dist'),
    filename: '[name].js',
  },

  module: {
    loaders: [
      {
        test: /\.(css|scss)$/,
        loader: ExtractTextPlugin.extract('style-loader', 'css-loader!sass-loader')
      },
      {
        test:    /\.html$/,
        exclude: /node_modules/,
        loader:  'file?name=[name].[ext]',
      },
      {
        test:    /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        loader:  'elm-webpack?pathToMake=./node_modules/.bin/elm-make',
      },
      {
        test: /\.woff(2)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        loader: 'url-loader?limit=10000&minetype=application/font-woff',
      },
      {
        test: /\.(ttf|eot|svg)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        loader: 'file-loader',
      },
    ],

    noParse: /\.elm$/,
  },

  plugins: [
    new ExtractTextPlugin("[name].css"),
    new CopyWebpackPlugin([
       { from: 'node_modules/ace-builds/src-min-noconflict/', to: 'ace-build/' },
       { from: 'node_modules/highlightjs/highlight.pack.min.js', to: 'highlightjs/' },
       { from: 'node_modules/highlightjs/styles/github.css', to: 'highlightjs/'},
       { from: 'assets/', to: 'assets/'}
    ]),
  ],

  devServer: {
    inline: true,
    stats: { colors: true },
  },

};
