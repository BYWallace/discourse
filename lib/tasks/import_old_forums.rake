require 'csv'

namespace :db do

  # Run this task first
  desc 'Import forum discussions from csv file'
  task import_forum_discussions: [:environment] do
    file = 'db/forum_discussions.csv'

    CSV.foreach(file, :headers => true) do |row|
      username = "#{FFaker::Internet.user_name[0..17]}#{rand(99)}"
      User.create!(id: row['created_user_id'].to_i, username: username, email: "#{username}@test.com") unless User.find_by_id(row['created_user_id'].to_i)
      # sleep 1
      topic = Topic.new(id: row['ugc_id'].to_i, title: "#{row['ugc_name']}", user_id: row['created_user_id'].to_i, category_id: Category.find_by_name(row['tag_text']).id)
      unless Topic.find_by_id(topic.id)
        topic.save(validate: false)
        topic.posts.create(user_id: row['created_user_id'].to_i, topic_id: topic.id, raw: row['description_text'])
      end
      # sleep 1
    end
  end

  # Run this task after importing discussions with the rake task above so comments can be linked
  desc 'Import forum comments from csv file'
  task import_forum_comments: [:environment] do
    file = 'db/forum_comments.csv'

    CSV.foreach(file, :headers => true) do |row|
      username = User.find_by_id(row['created_user_id'].to_i).try(:username) || "#{FFaker::Internet.user_name[0..17]}#{rand(99)}"
      User.create!(id: row['created_user_id'].to_i, username: username, email: "#{username}@test.com") unless User.find_by_id(row['created_user_id'].to_i)
      if Topic.find_by_id(row['ugc_id'].to_i)
        post = Post.new(topic_id: row['ugc_id'].to_i, user_id: row['created_user_id'].to_i, raw: row['comment_text'])
        post.save(validate: false)
      end
    end
  end
end

# You can run the following code to randomly generate like counts for each post
#     1000.times do |i|
#       PostAction.act(User.all.sample, Post.all.sample, PostActionType.types[:like])
#     end
