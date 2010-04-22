require File.dirname(__FILE__) + '/../test_helper'
require 'mysql_admins_controller'

# Re-raise errors caught by the controller.
class MysqlAdminsController; def rescue_action(e) raise e end; end

class MysqlAdminsControllerTest < Test::Unit::TestCase
  fixtures :mysql_admins

  def setup
    @controller = MysqlAdminsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = mysql_admins(:first).id
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:mysql_admins)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:mysql_admin)
    assert assigns(:mysql_admin).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:mysql_admin)
  end

  def test_create
    num_mysql_admins = MysqlAdmin.count

    post :create, :mysql_admin => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_mysql_admins + 1, MysqlAdmin.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:mysql_admin)
    assert assigns(:mysql_admin).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      MysqlAdmin.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      MysqlAdmin.find(@first_id)
    }
  end
end
