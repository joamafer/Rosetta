# JoseParser
JoseParser is a Mac app created on my own to save tons of time while working in my current company by automatically parsing the class models we need from Swagger.io API docs.



## Why?
In our company we use to work with Swagger.io. I was always finding myself time after time tediuosly copy-pasting the model from the online documentation just to generate our own model classes in Swift. It was a really tedious task and I was losing a lot of time just doing the same. So I thought that could be made in an automatic way. I decided to create this Mac OS app which generates the classes we need on its own.

## How it works
Basically you only need to paste the model class from Swagger.io and it will automatically create the Swift model class for you. Keep in mind that I have adapted the resulting code specifically to our components, so we have 100% fully ready and integrated classes for our projects. It's also mapping the enum values and creating the enumerations for you.

## That's all?
I have in mind a lot of improvements for this app, like:
- Change the behaviour so you only need to setup the url of the API docs, the client id and client secret and it will automatically detect and parse all the class models and generate all the class files for you. I have been researching about Swagger tools and it seems  that 'Swagger Codegen' could help with that, but I need some time for that.
- Allow to set the project path so the files are automatically created there.
- Improve massively the quality of the code. I made the app as a quick solution in a couple of days so needs lots of refactoring and improvements. Also needs to be robust and ready for Swift 3.0.
- Adapt it to other API docs services and frameworks (JSONDoc, Mashery, RestKit, etc).

Please feel free to write any comments, pull requests, fork it, etc!
