#
# Cookbook Name:: cooking-with-jenkins
# Definition:: cookbook_ci
#
# Sets up Jenkins jobs to test a specified Chef cookbook
#
# Copyright (C) 2013 Zachary Stevens
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

define :cookbook_ci, :branch => 'master', :foodcritic => true, :chefspec => false, :unit => false, :docker => false, :kitchen => false, :junit_results => false do
  job_name = "cookbook-#{params[:name]}"
  repo = params[:repository]

  job_config = File.join(Chef::Config[:file_cache_path], "#{job_name}-config.xml")

  jenkins_job job_name do
    action :nothing
    config job_config
  end

  commands = ["bundle install --deployment"]
  commands << "bundle exec rake lint" if params[:foodcritic]
  commands << "bundle exec rake spec" if params[:chefspec]
  commands << "bundle exec rake unit" if params[:serverspec]
  commands << "bundle exec rake docker" if params[:docker]
  commands << "bundle exec rake kitchen:all" if params[:kitchen]

  template job_config do
    source 'cookbook-job.xml.erb'
    variables :git_url => repo, :git_branch => params[:branch], :commands => commands.join("\n"), :params => params
    notifies  :update, "jenkins_job[#{job_name}]", :immediately
    notifies  :build, "jenkins_job[#{job_name}]", :immediately
  end
end
