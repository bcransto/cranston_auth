# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database..."

# Create admin users
admin1 = User.find_or_create_by!(email: 'admin@cranston.edu') do |user|
  user.password = 'password123'
  user.role = 'admin'
  user.first_name = 'Admin'
  user.last_name = 'User'
end
puts "Created admin: #{admin1.email}"

# Create teacher users
teacher1 = User.find_or_create_by!(email: 'teacher1@cranston.edu') do |user|
  user.password = 'password123'
  user.role = 'teacher'
  user.first_name = 'Jane'
  user.last_name = 'Smith'
end
puts "Created teacher: #{teacher1.email}"

teacher2 = User.find_or_create_by!(email: 'teacher2@cranston.edu') do |user|
  user.password = 'password123'
  user.role = 'teacher'
  user.first_name = 'John'
  user.last_name = 'Doe'
end
puts "Created teacher: #{teacher2.email}"

# Create student users
student1 = User.find_or_create_by!(email: 'student1@cranston.edu') do |user|
  user.password = 'password123'
  user.role = 'student'
  user.lasid = '1234'
  user.first_name = 'Alice'
  user.last_name = 'Johnson'
  user.nickname = 'Ali'
  user.date_of_birth = Date.new(2010, 5, 15)
end
puts "Created student: #{student1.email} (LASID: #{student1.lasid})"

student2 = User.find_or_create_by!(email: 'student2@cranston.edu') do |user|
  user.password = 'password123'
  user.role = 'student'
  user.lasid = '5678'
  user.first_name = 'Bob'
  user.last_name = 'Williams'
  user.date_of_birth = Date.new(2011, 8, 22)
end
puts "Created student: #{student2.email} (LASID: #{student2.lasid})"

student3 = User.find_or_create_by!(email: 'student3@cranston.edu') do |user|
  user.password = 'password123'
  user.role = 'student'
  user.lasid = '9012'
  user.first_name = 'Charlie'
  user.last_name = 'Brown'
  user.nickname = 'Chuck'
  user.date_of_birth = Date.new(2009, 12, 3)
end
puts "Created student: #{student3.email} (LASID: #{student3.lasid})"

puts "Database seeding completed!"
puts "Total users: #{User.count}"
puts "  Admins: #{User.admin.count}"
puts "  Teachers: #{User.teacher.count}"
puts "  Students: #{User.student.count}"
