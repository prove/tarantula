require 'machinist/active_record'
require 'faker'

###################################################
# Blueprints                                      #
###################################################

Project.blueprint do
  name { "Project #{Project.count}" }
end

class Project < ActiveRecord::Base
  def self.make_with_cases(atts)
    cases_count = atts.delete(:cases)
    p = Project.make!(atts)
    cases_count.times do
      Case.make_with_steps(:project => p)
    end
    p
  end
end

TestArea.blueprint do
  name    { "TestArea #{TestArea.count}" }
  project { Project.make! }
end

TestObject.blueprint do
  name    { "TestArea #{TestObject.count}" }
  date    { Date.today }
  project { Project.make! }
end

User.blueprint do
  login                 { "User #{User.count}"  }
  password              { "user#{User.count}"   }
  password_confirmation { "user#{User.count}"   }
  email                 { Faker::Internet.email }
end

Admin.blueprint do
  login                 { "Admin #{Admin.count}" }
  password              { "admin#{Admin.count}"  }
  password_confirmation { "admin#{Admin.count}"  }
  email                 { Faker::Internet.email  }
end

TestSet.blueprint do
  name     { "TestSet #{TestSet.count}" }
  project  { Project.make!              }
  priority { 0                          }
  date     { Date.today                 }
end

class TestSet < ActiveRecord::Base
  def self.make_with_cases(atts={}, case_atts={})
    cases_count = atts.delete(:cases) || rand(5)+1
    ts = TestSet.make!(atts)
    cases_count.times do |i|
      ts.cases << Case.make_with_steps({:position => i+1, :project => ts.project}.merge(case_atts))
    end
    ts
  end
end

Requirement.blueprint do
  name        { "req #{Requirement.count}" }
  external_id { "#{Requirement.count}"     }
  date        { Date.today                 }
  project     { Project.make!              }
  creator     { User.make!                 }
end

Case.blueprint do
  title      { Faker::Lorem.words(rand(5)+1).join(' ') }
  date       { Date.today                              }
  project    { Project.make!                           }
  creator    { User.make!                              }
  updater    { User.make!                              }
end

class Case < ActiveRecord::Base
  def self.make_with_steps(atts={})
    steps_count = atts.delete(:steps) || rand(5)+1
    c = Case.make!(atts)
    steps_count.times do |i|
      c.steps << Step.make!(:position => i)
    end
    c
  end
end

Step.blueprint do
  action { Faker::Lorem.sentence }
  result { Faker::Lorem.sentence }
end

Execution.blueprint do
  name        { Faker::Lorem.words(rand(5)+1).join(' ') }
  date        { Date.today                              }
  test_object { TestObject.make!                        }
  project     { Project.make!                           }
end

class Execution < ActiveRecord::Base
  def self.make_with_runs(atts={})
    cases_count = atts.delete(:cases) || rand(5)+1
    atts[:test_object] ||= TestObject.make!
    e = Execution.make!(atts)
    test_set = TestSet.make_with_cases(:cases => cases_count)
    updater = User.make!
    test_set.cases.each do |c|
      ce = CaseExecution.create_with_steps!(:execution => e,
                                            :case_id => c.id,
                                            :position => c.position)
      ce.step_executions.each do |se|
        se.update_attributes(:result =>
          ResultType.all[rand(ResultType.all.size)])
      end
      ce.update_result(updater)
    end
    e.save!
    e
  end
end

CaseExecution.blueprint do
  test_case { Case.make!     }
  execution { Execution.make!}
  result    { NotRun         }
  executor  { User.make!     }
  position  { rand(100)+1    }
end

StepExecution.blueprint do
  result { NotRun    }
  step   { Step.make!}
  comment { "Nasty comment < 3, because < or > breaks stuff." }
end

class CaseExecution < ActiveRecord::Base
  def self.make_with_result(atts={})
    if atts[:result] != NotRun
      atts[:executed_at] ||= Time.now
      atts[:executor] ||= User.make!
      atts[:execution] ||= Execution.make!
    end
    ce = CaseExecution.make!(atts)

    ce.test_case.steps.each do |step|
      ce.step_executions << StepExecution.make!(:result => ce.result,
                                                :step => step)
    end
    ce
  end
end

class Attachment < ActiveRecord::Base
  def self.make!
    c = Attachment.count
    ActiveRecord::Base.connection.execute(
      "INSERT INTO attachments (orig_filename, created_at) VALUES ('foo.bar',"+
      "'#{Time.now.to_s(:db)}')")
    Attachment.find(:all).last
  end
end

Tag.blueprint do
  name { "Tag #{Tag.count}" }
end

Bugzilla.blueprint do
  name      { 'mock bugzilla' }
  base_url  { 'base url'      }
  db_host   { 'bug_db_host'   }
  db_name   { 'bug_db_name'   }
  db_user   { 'bug_db_user'   }
  db_passwd { 'bug_db_passwd' }
  mock      { true }
end

ImportSource.blueprint do
  adapter   {'mysql'}
  host      {'db_host'}
  port      {'db_port'}
  database  {'db_name'}
  username  {'db_user'}
  password  {'db_passwd'}
  name      {'Jira connection'}
end

Jira.blueprint do
  name      { 'mock jira' }
  base_url  { 'base url'      }
  db_host   { 'bug_db_host'   }
  db_name   { 'bug_db_name'   }
  db_user   { 'bug_db_user'   }
  db_passwd { 'bug_db_passwd' }
  import_source { ImportSource.make! }
  mock      { true }
end

BugTracker.blueprint do
  name      { 'mock bugzilla' }
  base_url  { 'base url'      }
  db_host   { 'bug_db_host'   }
  db_name   { 'bug_db_name'   }
  db_user   { 'bug_db_user'   }
  db_passwd { 'bug_db_passwd' }
end

class BugTracker < ActiveRecord::Base
  def after_find
    @db = Bugzilla::MockDB
  end
  def after_validation
    if self.class == BugTracker
      class_eval{ define_method(:ping) {}}
      class_eval{ define_method(:refresh!) {}}
    end
  end
end

Bug.blueprint do
  bug_tracker    { Bugzilla.make!                                       }
  severity       { BugSeverity.make!(:bug_tracker => object.bug_tracker)}
  product        { BugProduct.make!(:bug_tracker => object.bug_tracker) }
  external_id    { "#{Bug.count}"                                       }
end

BugSeverity.blueprint do
  bug_tracker { Bugzilla.make!                      }
  external_id { "#{BugSeverity.count}"              }
  name        { "bug severity #{BugSeverity.count}" }
end

BugProduct.blueprint do
  bug_tracker { Bugzilla.make!                    }
  external_id { "#{BugProduct.count}"             }
  name        { "bug product #{BugProduct.count}" }
end

BugComponent.blueprint do
  bug_product { BugProduct.make!                      }
  external_id { "#{BugComponent.count}"               }
  name        { "bug component #{BugComponent.count}" }
end
