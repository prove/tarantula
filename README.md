# Agile Test Management

Tarantula is modern tool for managing software testing in agile
software projects. It's free, licensed as open source software under
GNU GPLv3.

[www.testiatarantula.com](http://www.testiatarantula.com)

## This is a fork that is intended to add folloving features to the original tarantula:
- REST API 
- integration with Testing Automation Tool
- more versalite jira integration

### Jira integration

Suppose you have Jira bug tracker set up and a test case execution with following results.  
1. Step1 - PASSED  
2. Step2 - PASSED  
3. Step3 - FAILED  
  
After choosing "Add defect to bug tracker" inside the "Associate defect" dialog tarantula redirects you to appropriate "create new issue" form with following fields filled in:  
**title** test case title  
**description**  
Preconditions => test case preconditions  
Step1 action  
Step2 action  
Result  
Expected result  

### Tarantula API

The REST API is used in the sense of doing POST HTTP requests with XML-ed params inside

#### Authentication

[Basic http authentication](http://en.wikipedia.org/wiki/Basic_access_authentication) is used. Just provide a username and a password of existing tarantula user, who has enough privileges to perform actions below  
The credentials are transmitted without encription. If you need more safety please request for SSL support  


#### Create testcase
*Preconditions*  
- There is project "My project" in the system  
  
Following call will create new test case with specified parameters  

		http://username:password@tarantula_url/api/create_testcase.xml  
   
where body is  

		<request>
			<testcase project="My project" title="testcase title" priority="high" tags="functional" objective="testcase objective" data="testcase data" preconditions="testcase preconditions">
				<step action="Step 1" result="Result 1"></step>
				<step action="Step 2" result="Result 2"></step>
			</testcase>
		</request>

This method can be invoked e.g. for inmorting testcases fro a third party tool like testlink

#### Update testcase execution
*Preconditions*  
- There is project "My project" in the system  
- There is execution "My execution" in the system  
- There is testcase "My testcase" in the system inside "My execution"  
- Test step has at least 2 steps
  
Following call will update testcase execution setting run time to "1", step1 result to "Passed", step2 result to "Not implemented"

		http://username:password@tarantula_url/api/update_testcase_execution.xml  
   
where body is  

		<request>
			<project>My project</project>
			<execution>My execution</execution>
			<testcase>My testcase</testcase>
			<duration>1</duration>
			<step position="1" result="PASSED" comment="some text"></step>
			<step position="2" result="NOT_IMPLEMENTED"></step>
		</request>
  
The other possible options for result are: "FAILED", "SKIPPED", "NOT\_RUN", 
  
This method can be invoked e.g. for integrating with a test automation tool

#### Unblock testcase execution
*Preconditions*  
- There is project "My project" in the system  
- There is execution "My execution" in the system  
- There is testcase "My testcase" in the system inside "My execution"  
- "My testcase" is being blocked by automation tool
  
Following call will ublock testcase execution

		http://username:password@tarantula_url/api/unblock_testcase_execution.xml  
   
where body is  

		<request>
			<project>My project</project>
			<execution>My execution</execution>
			<testcase>My testcase</testcase>
		</request>
  
This method can be invoked e.g. for integrating with a test automation tool

### Automation tool integrattion

*Integration features are following*
- define automation tool similar to bug tracker definition
- automation tool will be executed according to your definition CMD string (the easiest way is to install automation tool 'next' to the tarantula installation)
- special symbols ${project}, ${execution}, ${testcase}, ${steps} inside CMD string are used to map tarantula test case execution to automated test. These symbols will be replaced with corresponding values
- automation TAG allows indicating automated tests among others
- each test tagged as automated has a cogwheel ENABLED, which triggers execution of the CMD, specified for this automation tool
- to get result from automation tool back to tarantula, tarantula API should be used (Update testcase execution method)

*Integration workflow is following*
1. Define Automation tool
2. Tag tests, which are automated with automation tag, defined in step 1
3. During test execution cogwheel is used to start test in automation mode
4. After the test has been started in automation mode, Tarantula blocks it's manual execution, until Tarantula API call "Unblock testcase execution" is received
5. It's expected that Automation tool makes two API calls after corresponding testcase had been executed: "Unblock testcase execution", "Update testcase execution with execution results"

*Example with Automation tool = ruby RSPEC*

CMD = 'exec_rspec.sh "${project}" "${execution}" "${test}" "${steps}"'
Where exec_spec.sh looks like this:
<pre><code>
  #!/bin/sh -xe
	# changing dir to Automation tool home
	cd $AT_HOME
	# setting up variables
	project="$1" 
	execution="$2" 
	testcase="$3"
	steps="$4" 
	# executing rspec (only $testcase example) with custom formatter
	# custom formatter implements "Update testcase execution" callback to tarantula
  # "|| true" string ensures the execution of the next command in case if rspec fails with uncought exception
  # after test is executed, CustomTarantulaFormatter initiates Tarantula API call "Update testcase execution" with corresponding execution results
	project=$project execution=$execution test=$testcase steps=$steps bundle exec rspec -e "$testcase" -r ./lib/CustomTarantulaFormatter.rb -f CustomTarantulaFormatter || true
	# this command initiates "Unblock testcase execution" Tarantula API call
	bundle exec rake unblock_test["""$project""","""$execution""","""$testcase"""] 
</code></pre>




