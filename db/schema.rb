# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120905062740) do

  create_table "attachment_sets", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "host_id"
    t.string   "host_type"
    t.integer  "host_version"
  end

  create_table "attachment_sets_attachments", :id => false, :force => true do |t|
    t.integer "attachment_set_id"
    t.integer "attachment_id"
  end

  create_table "attachments", :force => true do |t|
    t.string   "orig_filename"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type",          :default => "Attachment"
    t.text     "data"
  end

  create_table "bug_components", :force => true do |t|
    t.string   "name"
    t.string   "external_id"
    t.integer  "bug_product_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bug_components", ["bug_product_id"], :name => "index_bug_components_on_bug_product_id"
  add_index "bug_components", ["external_id"], :name => "index_bug_components_on_external_id"

  create_table "bug_products", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.integer  "bug_tracker_id"
    t.string   "external_id"
  end

  add_index "bug_products", ["bug_tracker_id"], :name => "index_bug_products_on_bug_tracker_id"
  add_index "bug_products", ["external_id"], :name => "index_bug_products_on_external_id"

  create_table "bug_products_projects", :id => false, :force => true do |t|
    t.integer "bug_product_id"
    t.integer "project_id"
  end

  add_index "bug_products_projects", ["bug_product_id", "project_id"], :name => "index_bug_products_projects_on_bug_product_id_and_project_id"

  create_table "bug_products_test_areas", :id => false, :force => true do |t|
    t.integer "bug_product_id"
    t.integer "test_area_id"
  end

  add_index "bug_products_test_areas", ["bug_product_id", "test_area_id"], :name => "index_bug_products_test_areas_on_bug_product_id_and_test_area_id"

  create_table "bug_severities", :force => true do |t|
    t.integer "bug_tracker_id"
    t.string  "name"
    t.string  "sortkey"
    t.string  "external_id"
  end

  add_index "bug_severities", ["bug_tracker_id"], :name => "index_bug_severities_on_bug_tracker_id"
  add_index "bug_severities", ["external_id"], :name => "index_bug_severities_on_external_id"
  add_index "bug_severities", ["sortkey"], :name => "index_bug_severities_on_sortkey"

  create_table "bug_snapshots", :force => true do |t|
    t.integer  "bug_id"
    t.integer  "bug_tracker_snapshot_id"
    t.integer  "bug_component_id"
    t.integer  "bug_product_id"
    t.integer  "bug_severity_id"
    t.integer  "created_by"
    t.string   "external_id"
    t.string   "priority"
    t.boolean  "reported_via_tarantula"
    t.string   "status"
    t.string   "summary"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.time     "lastdiffed"
  end

  add_index "bug_snapshots", ["bug_component_id"], :name => "index_bug_snapshots_on_bug_component_id"
  add_index "bug_snapshots", ["bug_id"], :name => "index_bug_snapshots_on_bug_id"
  add_index "bug_snapshots", ["bug_product_id"], :name => "index_bug_snapshots_on_bug_product_id"
  add_index "bug_snapshots", ["bug_severity_id"], :name => "index_bug_snapshots_on_bug_severity_id"
  add_index "bug_snapshots", ["bug_tracker_snapshot_id"], :name => "index_bug_snapshots_on_bug_tracker_snapshot_id"
  add_index "bug_snapshots", ["external_id"], :name => "index_bug_snapshots_on_external_id"
  add_index "bug_snapshots", ["lastdiffed"], :name => "index_bug_snapshots_on_lastdiffed"
  add_index "bug_snapshots", ["priority"], :name => "index_bug_snapshots_on_priority"
  add_index "bug_snapshots", ["status"], :name => "index_bug_snapshots_on_status"

  create_table "bug_tracker_snapshots", :force => true do |t|
    t.integer  "bug_tracker_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
  end

  add_index "bug_tracker_snapshots", ["bug_tracker_id"], :name => "index_bug_tracker_snapshots_on_bug_tracker_id"

  create_table "bug_trackers", :force => true do |t|
    t.string   "name"
    t.string   "base_url"
    t.string   "db_host"
    t.string   "db_port"
    t.string   "db_name"
    t.string   "db_user"
    t.string   "db_passwd"
    t.datetime "last_fetched",                     :default => '1900-01-01 00:00:00'
    t.string   "type",                             :default => "Bugzilla"
    t.integer  "import_source_id"
    t.boolean  "sync_project_with_classification", :default => false
  end

  create_table "bugs", :force => true do |t|
    t.integer  "bug_tracker_id"
    t.integer  "bug_severity_id"
    t.string   "external_id"
    t.string   "summary"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "bug_product_id"
    t.integer  "bug_component_id"
    t.string   "status"
    t.integer  "created_by"
    t.string   "priority"
    t.boolean  "reported_via_tarantula", :default => false
    t.time     "lastdiffed"
    t.string   "url"
  end

  add_index "bugs", ["bug_component_id"], :name => "bugs_bug_component"
  add_index "bugs", ["bug_component_id"], :name => "index_bugs_on_bug_component_id"
  add_index "bugs", ["bug_product_id"], :name => "bugs_bug_product"
  add_index "bugs", ["bug_product_id"], :name => "index_bugs_on_bug_product_id"
  add_index "bugs", ["bug_severity_id"], :name => "bugs_bug_severity"
  add_index "bugs", ["bug_severity_id"], :name => "index_bugs_on_bug_severity_id"
  add_index "bugs", ["bug_tracker_id"], :name => "bugs_bug_tracker"
  add_index "bugs", ["bug_tracker_id"], :name => "index_bugs_on_bug_tracker_id"
  add_index "bugs", ["external_id"], :name => "index_bugs_on_external_id"
  add_index "bugs", ["id"], :name => "bugs_id", :unique => true
  add_index "bugs", ["lastdiffed"], :name => "index_bugs_on_lastdiffed"
  add_index "bugs", ["priority"], :name => "index_bugs_on_priority"
  add_index "bugs", ["status"], :name => "index_bugs_on_status"

  create_table "case_avg_duration", :id => false, :force => true do |t|
    t.integer "case_id",                                      :default => 0, :null => false
    t.integer "project_id"
    t.integer "time_estimate"
    t.decimal "avg_duration",  :precision => 14, :scale => 4
  end

  create_table "case_executions", :force => true do |t|
    t.integer  "case_id"
    t.string   "result"
    t.datetime "created_at"
    t.integer  "created_by"
    t.integer  "execution_id"
    t.integer  "case_version"
    t.integer  "assigned_to"
    t.datetime "executed_at"
    t.integer  "executed_by"
    t.integer  "duration",     :default => 0
    t.integer  "position",     :default => 0
    t.string   "title"
  end

  add_index "case_executions", ["case_id"], :name => "index_case_executions_on_case_id"
  add_index "case_executions", ["case_version"], :name => "index_case_executions_on_case_version"
  add_index "case_executions", ["executed_by"], :name => "index_case_executions_on_executed_by"
  add_index "case_executions", ["execution_id"], :name => "index_case_executions_on_execution_id"
  add_index "case_executions", ["result"], :name => "index_case_executions_on_result"

  create_table "case_versions", :force => true do |t|
    t.integer  "case_id"
    t.integer  "version"
    t.string   "title"
    t.integer  "created_by"
    t.datetime "created_at"
    t.integer  "updated_by"
    t.datetime "updated_at"
    t.text     "objective"
    t.text     "test_data"
    t.text     "preconditions_and_assumptions"
    t.integer  "time_estimate"
    t.integer  "project_id"
    t.boolean  "deleted",                       :default => false
    t.integer  "original_id"
    t.string   "change_comment",                :default => ""
    t.string   "external_id"
    t.date     "date"
    t.integer  "priority",                      :default => 0
    t.boolean  "archived",                      :default => false
  end

  add_index "case_versions", ["case_id"], :name => "index_case_versions_on_case_id"
  add_index "case_versions", ["version"], :name => "index_case_versions_on_version"

  create_table "cases", :force => true do |t|
    t.string   "title"
    t.integer  "created_by"
    t.datetime "created_at"
    t.integer  "updated_by"
    t.datetime "updated_at"
    t.text     "objective"
    t.text     "test_data"
    t.text     "preconditions_and_assumptions"
    t.integer  "time_estimate"
    t.integer  "project_id"
    t.integer  "version",                       :default => 1
    t.boolean  "deleted",                       :default => false
    t.integer  "original_id"
    t.string   "change_comment",                :default => ""
    t.string   "external_id"
    t.date     "date"
    t.integer  "priority",                      :default => 0
    t.boolean  "archived",                      :default => false
  end

  add_index "cases", ["deleted"], :name => "index_cases_on_deleted"
  add_index "cases", ["id"], :name => "index_cases_on_id"
  add_index "cases", ["priority", "title"], :name => "index_cases_on_priority_and_title"
  add_index "cases", ["project_id"], :name => "index_cases_on_project_id"

  create_table "cases_requirements", :id => false, :force => true do |t|
    t.integer "case_id"
    t.integer "requirement_id"
    t.integer "case_version"
    t.integer "requirement_version"
  end

  create_table "cases_steps", :id => false, :force => true do |t|
    t.integer "case_id"
    t.integer "case_version"
    t.integer "position"
    t.integer "step_id"
    t.integer "step_version"
  end

  add_index "cases_steps", ["case_id"], :name => "index_cases_steps_on_case_id"

  create_table "cases_test_areas", :id => false, :force => true do |t|
    t.integer "case_id"
    t.integer "test_area_id"
  end

  create_table "cases_test_sets", :id => false, :force => true do |t|
    t.integer "case_id",                         :null => false
    t.integer "test_set_id",                     :null => false
    t.integer "position"
    t.integer "version",          :default => 1
    t.integer "test_set_version", :default => 1
    t.integer "case_version"
  end

  add_index "cases_test_sets", ["case_id"], :name => "index_cases_test_sets_on_case_id"
  add_index "cases_test_sets", ["case_version"], :name => "index_cases_test_sets_on_test_case_version"
  add_index "cases_test_sets", ["test_set_id"], :name => "index_cases_test_sets_on_test_set_id"
  add_index "cases_test_sets", ["test_set_version"], :name => "index_cases_test_sets_on_test_set_version"

  create_table "customer_configs", :force => true do |t|
    t.string   "name"
    t.text     "value"
    t.boolean  "required"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.string   "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "queue"
  end

  add_index "delayed_jobs", ["locked_by"], :name => "index_delayed_jobs_on_locked_by"

  create_table "executions", :force => true do |t|
    t.string   "name"
    t.integer  "test_set_id"
    t.datetime "created_at"
    t.integer  "created_by"
    t.datetime "updated_at"
    t.integer  "updated_by"
    t.integer  "test_set_version", :default => 1
    t.boolean  "deleted",          :default => false
    t.integer  "version",          :default => 0
    t.integer  "test_object_id"
    t.integer  "project_id"
    t.boolean  "completed",        :default => false
    t.date     "date"
    t.boolean  "archived",         :default => false
  end

  add_index "executions", ["deleted"], :name => "index_executions_on_deleted"
  add_index "executions", ["id"], :name => "index_executions_on_id"
  add_index "executions", ["project_id"], :name => "index_executions_on_project_id"
  add_index "executions", ["test_object_id"], :name => "index_executions_on_test_object_id"
  add_index "executions", ["test_set_id"], :name => "index_executions_on_test_set_id"
  add_index "executions", ["test_set_version"], :name => "index_executions_on_test_set_version"

  create_table "executions_test_areas", :id => false, :force => true do |t|
    t.integer "execution_id"
    t.integer "test_area_id"
  end

  create_table "import_sources", :force => true do |t|
    t.string  "name"
    t.string  "adapter"
    t.string  "host"
    t.string  "username"
    t.string  "password"
    t.string  "database"
    t.integer "port"
  end

  create_table "password_resets", :force => true do |t|
    t.string   "link"
    t.boolean  "activated",  :default => false
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "preferences", :force => true do |t|
    t.string  "type"
    t.integer "user_id"
    t.integer "project_id"
    t.text    "data"
  end

  create_table "project_assignments", :force => true do |t|
    t.integer "project_id",                            :null => false
    t.integer "user_id",                               :null => false
    t.string  "group",            :default => "GUEST", :null => false
    t.integer "test_area_id"
    t.boolean "test_area_forced", :default => false
    t.integer "test_object_id"
  end

  create_table "projects", :force => true do |t|
    t.string  "name"
    t.text    "description"
    t.boolean "deleted",        :default => false
    t.integer "version",        :default => 0
    t.boolean "library",        :default => false
    t.integer "bug_tracker_id"
  end

  create_table "report_data", :force => true do |t|
    t.string   "key"
    t.integer  "project_id"
    t.integer  "user_id"
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "requirement_versions", :force => true do |t|
    t.integer  "requirement_id"
    t.integer  "version"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "external_id"
    t.string   "name"
    t.integer  "project_id"
    t.integer  "created_by"
    t.date     "date"
    t.boolean  "deleted"
    t.date     "external_modified_on"
    t.text     "description"
    t.string   "priority"
    t.text     "optionals"
    t.boolean  "archived",             :default => false
  end

  create_table "requirements", :force => true do |t|
    t.string   "external_id"
    t.string   "name"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "deleted",              :default => false
    t.integer  "created_by"
    t.date     "external_modified_on"
    t.text     "description"
    t.string   "priority"
    t.text     "optionals"
    t.date     "date"
    t.integer  "version",              :default => 1
    t.boolean  "archived",             :default => false
  end

  add_index "requirements", ["external_id"], :name => "index_requirements_on_external_id"
  add_index "requirements", ["name"], :name => "index_requirements_on_name"
  add_index "requirements", ["project_id"], :name => "index_requirements_on_project_id"

  create_table "requirements_test_areas", :id => false, :force => true do |t|
    t.integer "requirement_id"
    t.integer "test_area_id"
  end

  create_table "step_executions", :force => true do |t|
    t.integer "step_id"
    t.string  "result",            :limit => 10
    t.integer "case_execution_id"
    t.text    "comment"
    t.integer "step_version"
    t.integer "position",                        :default => 0
    t.integer "bug_id"
  end

  add_index "step_executions", ["case_execution_id"], :name => "index_step_executions_on_case_execution_id"
  add_index "step_executions", ["step_id"], :name => "index_step_executions_on_step_id"

  create_table "step_versions", :force => true do |t|
    t.integer  "step_id"
    t.integer  "version"
    t.integer  "case_id"
    t.text     "action"
    t.text     "result"
    t.integer  "order"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "deleted",     :default => false
    t.string   "external_id"
  end

  add_index "step_versions", ["case_id"], :name => "index_step_versions_on_case_id"
  add_index "step_versions", ["step_id"], :name => "index_step_versions_on_step_id"

  create_table "steps", :force => true do |t|
    t.text     "action"
    t.text     "result"
    t.integer  "version",     :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "deleted",     :default => false
    t.string   "external_id"
  end

  create_table "taggings", :force => true do |t|
    t.integer "tag_id",                        :null => false
    t.integer "taggable_id",                   :null => false
    t.string  "taggable_type", :default => "", :null => false
  end

  add_index "taggings", ["tag_id", "taggable_id", "taggable_type"], :name => "index_taggings_on_tag_id_and_taggable_id_and_taggable_type", :unique => true
  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id"], :name => "index_taggings_on_taggable_id"
  add_index "taggings", ["taggable_type"], :name => "index_taggings_on_taggable_type"

  create_table "tags", :force => true do |t|
    t.string  "name",          :default => "", :null => false
    t.integer "project_id"
    t.string  "taggable_type"
  end

  add_index "tags", ["id"], :name => "index_tags_on_id"
  add_index "tags", ["name"], :name => "index_tags_on_name"

  create_table "tasks", :force => true do |t|
    t.string   "type"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "assigned_to"
    t.boolean  "finished",      :default => false
    t.integer  "project_id"
    t.integer  "created_by"
  end

  create_table "test_areas", :force => true do |t|
    t.string   "name"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "test_areas_test_objects", :id => false, :force => true do |t|
    t.integer "test_object_id"
    t.integer "test_area_id"
  end

  create_table "test_areas_test_sets", :id => false, :force => true do |t|
    t.integer "test_set_id"
    t.integer "test_area_id"
  end

  create_table "test_objects", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "project_id"
    t.date     "date"
    t.string   "esw"
    t.string   "swa"
    t.string   "hardware"
    t.string   "mechanics"
    t.text     "description"
    t.boolean  "deleted",     :default => false
    t.boolean  "archived",    :default => false
  end

  add_index "test_objects", ["created_at"], :name => "index_test_objects_on_created_at"
  add_index "test_objects", ["date"], :name => "index_test_objects_on_date"
  add_index "test_objects", ["name"], :name => "index_test_objects_on_name"
  add_index "test_objects", ["project_id"], :name => "index_test_objects_on_project_id"

  create_table "test_set_versions", :force => true do |t|
    t.integer  "test_set_id"
    t.integer  "version"
    t.string   "name"
    t.datetime "created_at"
    t.integer  "created_by"
    t.datetime "updated_at"
    t.integer  "updated_by"
    t.integer  "project_id"
    t.boolean  "deleted",     :default => false
    t.integer  "priority",    :default => 0
    t.string   "external_id"
    t.date     "date"
    t.boolean  "archived",    :default => false
  end

  add_index "test_set_versions", ["test_set_id"], :name => "index_test_set_versions_on_test_set_id"

  create_table "test_sets", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.integer  "created_by"
    t.datetime "updated_at"
    t.integer  "updated_by"
    t.integer  "project_id"
    t.integer  "version",     :default => 1
    t.boolean  "deleted",     :default => false
    t.integer  "priority",    :default => 0
    t.string   "external_id"
    t.date     "date"
    t.boolean  "archived",    :default => false
  end

  add_index "test_sets", ["priority", "name"], :name => "index_test_sets_on_priority_and_name"
  add_index "test_sets", ["project_id"], :name => "index_test_sets_on_project_id"

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "phone"
    t.string   "realname"
    t.text     "description"
    t.integer  "latest_project_id"
    t.string   "time_zone"
    t.boolean  "deleted",                                 :default => false
    t.integer  "version",                                 :default => 0
    t.string   "type",                                    :default => "User"
    t.string   "md5_password"
  end

end
