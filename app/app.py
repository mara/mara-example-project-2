from mara_app.app import MaraApp


app = MaraApp()

# from werkzeug.contrib.profiler import ProfilerMiddleware
# app.wsgi_app = ProfilerMiddleware(app.wsgi_app, profile_dir='/tmp/')

wsgi_app = app.wsgi_app
