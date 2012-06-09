Tarantula::Application.routes do
  match '', :to => "home#index"

  resources :password_resets

  resource :archive, :only => [:destroy, :create],
    :path_prefix => '/projects/:project_id/:resources',
    :controller => 'archives'

  resources :projects, :member => {
    :priorities => :get,
    :deleted => :delete, :products => :get},
    :collection => {:deleted => :get} do |project|

    project.resources :users do |user|
      user.resources :executions
      user.resource :test_area
      user.resource :test_object
      user.resources :report_data
    end

    project.resources :test_sets do |tset|
      tset.resources :cases, :collection => {:not_in_set => :get}
    end
    project.resources :attachments
    project.resources :cases
    project.resources :executions
    project.resources :requirements
    project.resources :tags
    project.resources :tasks
    project.resources :test_objects do |tob|
      tob.resources :attachments
    end
    project.resources :test_areas
    project.resources :bug_trackers, :member => {:products => :get}
    project.resources :bugs
  end

  resources :requirements do |req|
    req.resources :cases, :only => [:index]
    req.resources :attachments
  end

  resources :test_sets do |tset|
    tset.resources :cases, :collection => {:not_in_set => :get}
  end

  resources :cases, :member => {:change_history => :get} do |tcase|
    tcase.resources :attachments
    tcase.resources :tasks
    tcase.resources :requirements, :only => [:index]
  end

  resources :case_executions, :has_many => :attachments

  resources :executions do |texec|
    texec.resources :case_executions
  end

  resources :test_objects, :only => [:show] do |tobs|
    tobs.resources :attachments
  end

  resources :users, :member => {:selected_project => :put, :permissions => :get, :available_groups => :get},
    :collection => {:deleted => :get} do |users|
    users.resources :projects, :member => {:group => :get}, :collection => {:deleted => :get}
    users.resources :executions
    users.resources :tasks
  end

  resources :bug_trackers, :member => {:products => :get}

  resources :customer_configs
  match 'restart', 'customer_configs#restart'

  resource :report, :member => {:dashboard => :get,
                                :test_result_status => :get,
                                :results_by_test_object => :get,
                                :case_execution_list => :get,
                                :test_efficiency => :get,
                                :status => :get,
                                :requirement_coverage => :get,
                                :bug_trend => :get,
                                :workload => :get},
               :controller => 'report'

  resource :home, :member => {:login => [:get, :post],
                                  :logout => :get,
                                  :index => :get},
               :controller => 'home'

  resource :import, :member => {:doors => [:get, :post]},
           :controller => 'import'

end
