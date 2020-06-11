import flask

blueprint = flask.Blueprint('start_page', __name__)


@blueprint.route('/')
def start_page():
    return flask.redirect(flask.url_for('mara_pipelines.node_page'))
#    return response.Response(title='Welcome', html=_.div['nothing to see yet'])
