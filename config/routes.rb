Tarantula::Application.routes do
  match '', :to => "home#index"

  resources :password_resets

  resource :archive, :only => [:destroy, :create],
    :path_prefix => '/projects/:project_id/:resources',
    :controller => 'archives'

  resources :projects, :member => {
    :priorities => :get,
    :deleted => :delete, :products => :get},
    :collection => {:deleted => :get} do

    resources :users do
      resources :executions
      resource :test_area
      resource :test_object
      resources :report_data
    end

    resources :test_sets do
      resources :cases, :collection => {:not_in_set => :get}
    end
    resources :attachments
    resources :cases
    resources :executions
    resources :requirements
    resources :tags
    resources :tasks
    resources :test_objects do
      resources :attachments
    end
    resources :test_areas
    resources :bug_trackers, :member => {:products => :get}
    resources :bugs
  end

  resources :requirements do
    resources :cases, :only => [:index]
    resources :attachments
  end

  resources :test_sets do
    resources :cases, :collection => {:not_in_set => :get}
  end

  resources :cases, :member => {:change_history => :get} do
    resources :attachments
    resources :tasks
    resources :requirements, :only => [:index]
  end

  resources :case_executions, :has_many => :attachments

  resources :executions do
    resources :case_executions
  end

  resources :test_objects, :only => [:show] do
    resources :attachments
  end

  resources :users, :member => {:selected_project => :put, :permissions => :get, :available_groups => :get},
    :collection => {:deleted => :get} do
    resources :projects, :member => {:group => :get}, :collection => {:deleted => :get}
    resources :executions
    resources :tasks
  end

  resources :bug_trackers, :member => {:products => :get}

  resources :customer_configs
  # match 'restart', 'customer_configs#restart'

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
