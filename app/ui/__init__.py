"""Set up Navigation, ACL & Logos"""

import data_integration
import data_sets
import flask
import mara_acl
import mara_acl.users
import mara_app
import mara_app.layout
import mara_db
import mara_page.acl
from mara_app import monkey_patch
from mara_page import acl
from mara_page import navigation

from app.ui import start_page

blueprint = flask.Blueprint('ui', __name__, url_prefix='/ui', static_folder='static')


def MARA_FLASK_BLUEPRINTS():
    return [start_page.blueprint, blueprint]


# replace logo and favicon
monkey_patch.patch(mara_app.config.favicon_url)(lambda: flask.url_for('ui.static', filename='favicon.ico'))
monkey_patch.patch(mara_app.config.logo_url)(lambda: flask.url_for('ui.static', filename='logo.png'))


# add custom css
@monkey_patch.wrap(mara_app.layout.css_files)
def css_files(original_function, response):
    files = original_function(response)
    files.append(flask.url_for('ui.static', filename='styles.css'))
    return files


# define protected ACL resources
@monkey_patch.patch(mara_acl.config.resources)
def acl_resources():
    return [acl.AclResource(name='Documentation',
                            children=[data_integration.MARA_ACL_RESOURCES().get('Data Integration'),
                                      mara_db.MARA_ACL_RESOURCES().get('DB Schema')]),
            acl.AclResource(name='Admin',
                            children=[mara_app.MARA_ACL_RESOURCES().get('Configuration'),
                                      mara_acl.MARA_ACL_RESOURCES().get('Acl')])]


# activate ACL
monkey_patch.patch(mara_page.acl.current_user_email)(mara_acl.users.current_user_email)
monkey_patch.patch(mara_page.acl.current_user_has_permissions)(mara_acl.permissions.current_user_has_permissions)
monkey_patch.patch(mara_page.acl.user_has_permissions)(mara_acl.permissions.user_has_permissions)

monkey_patch.patch(mara_acl.config.whitelisted_uris)(lambda: ['/mara-app/navigation-bar'])


# navigation bar (other navigation entries will be automatically added)
@monkey_patch.patch(mara_app.config.navigation_root)
def navigation_root() -> navigation.NavigationEntry:
    return navigation.NavigationEntry(label='Root', children=[
        data_integration.MARA_NAVIGATION_ENTRIES().get('Data Integration'),
        data_sets.MARA_NAVIGATION_ENTRIES().get('Data Sets'),
        mara_db.MARA_NAVIGATION_ENTRIES().get('DB Schema'),
        navigation.NavigationEntry(
            'Settings', icon='cog', description='ACL & Configuration', rank=100,
            children=[mara_app.MARA_NAVIGATION_ENTRIES().get('Package Configs'),
                      mara_acl.MARA_NAVIGATION_ENTRIES().get('Acl')])])
