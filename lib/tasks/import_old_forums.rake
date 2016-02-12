require 'csv'

namespace :db do

  # Run this task first
  desc 'Import forum discussions from csv file'
  task import_forum_discussions: [:environment] do
    file = 'db/forum_discussions.csv'
    system_user = User.find_by_name('system')
    RateLimiter.disable

    ActiveRecord::Base.transaction do
      CSV.foreach(file, headers: true) do |row|
        unless Topic.exists?(id: row['ugc_id'])
          username = "#{FFaker::Internet.user_name[0..10]}#{$.}"

          user = User.find_or_create_by!(id: row['created_user_id']) do |u|
            u.username = username
            u.email = "#{username}@test.com"
          end

          category = Category.find_or_create_by(name: row['tag_text']) do |c|
            c.user = system_user
          end

          topic = user.topics.build(id: row['ugc_id'], title: "#{row['ugc_name']}", user_id: row['created_user_id'], category_id: category.id)
          topic.posts.build(user_id: row['created_user_id'].to_i, topic_id: topic.id, raw: row['description_text'])
          topic.save(validate: false)
        end
      end
    end
    RateLimiter.enable
  end

  # Run this task after importing discussions with the rake task above so comments can be linked
  desc 'Import forum comments from csv file'
  task import_forum_comments: [:environment] do
    file = 'db/forum_comments.csv'
    RateLimiter.disable

    ActiveRecord::Base.transaction do
      CSV.foreach(file, headers: true) do |row|
        if Topic.exists?(row['ugc_id'])
          username = "#{FFaker::Internet.user_name[0..10]}#{$.}"

          user = User.find_or_create_by!(id: row['created_user_id']) do |u|
            u.username ||= username
            u.email ||= "#{username}@test.com"
          end

          user.posts.create(topic_id: row['ugc_id'].to_i, raw: row['comment_text'])
        end
      end
    end
    RateLimiter.enable
  end
end
# You can run the following code to randomly generate like counts for each post
#     1000.times do |i|
#       PostAction.act(User.all.sample, Post.all.sample, PostActionType.types[:like])
#     end
