# Google Bulk Deindexer

A tool to bulk request to deindex URLs from Google Webmaster Tool

## Pre-requisite

* Firefox
* Ruby

```
gem install bundler
bundle install
```

* config.json

You need to generate config.json containing the following configuration

```
{
  "credential": {
    "username": "<google webmaster tool username>",
    "password": "<google webmaser tool password>"
  },
  "mailto": [
    "<email to send the status>",
    "<email2 to send the status>",
    ...
  ]
}
```

NOTE: config.json is in .gitignore, and will not be checked into git.

## How to run

### From commandline

```
ruby deindexer_cmdline.rb <file containing list of urls to remove>
```

For example, if you have a file called rem.txt with the following urls to remove:

```
http://www.example.com/abc
http://www.example.com/xyz
```

you can run

```
ruby deindexer_cmdline.rb rem.txt
```

* NOTE: Each URL should be on a separate line.

You will get tab-separted result per request, like so:

```
2016-01-08 00:21:28	  https://www.example.com/abc	http://www.example.com/abc has been added for removal.
2016-01-08 00:23:28	  https://www.example.com/xyz	http://www.example.com/xyz has been added for removal.
```

### From UI

deindexer_ui.rb is a sinatra/rack app providing frontend to the commandline tool. 

```
rackup
```

* You can now access http://localhost:9292/ to access the UI
* Upon submission, the job will run in background to request deindex, then email to mailto in config.json the result.
* The processed result will be recorded in data/history.tsv
