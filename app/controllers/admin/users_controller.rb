module Admin
  class UsersController < Admin::ApplicationController
    before_action :set_user, only: [:show, :edit, :update, :destroy, :restore]
    
    def index
      @users = User.all
    end

    def show
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)
      if @user.save
        redirect_to admin_user_path(@user), notice: 'User created successfully.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: 'User updated successfully.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @user.soft_delete
      redirect_to admin_users_path, notice: 'User deleted successfully.'
    end

    def restore
      @user.restore
      redirect_to admin_user_path(@user), notice: 'User restored successfully.'
    end

    def batch_new
      # Display the batch import form
    end

    def batch_create
      csv_text = params[:csv_data]
      @results = { success: [], errors: [] }
      
      if csv_text.blank?
        redirect_to batch_new_admin_users_path, alert: 'Please provide CSV data'
        return
      end
      
      ActiveRecord::Base.transaction do
        csv_text.split("\n").each_with_index do |line, index|
          next if line.strip.blank?
          next if index == 0 && line.downcase.include?('email') # Skip header row
          
          # Parse CSV line (email,password,role,lasid,first_name,last_name,nickname,date_of_birth)
          data = line.strip.split(',').map(&:strip)
          
          user_attributes = {
            email: data[0],
            password: data[1],
            role: data[2]&.downcase || 'student',
            lasid: data[3].presence,
            first_name: data[4].presence,
            last_name: data[5].presence,
            nickname: data[6].presence,
            date_of_birth: data[7].presence
          }
          
          user = User.new(user_attributes)
          
          if user.save
            @results[:success] << "Row #{index + 1}: Created user #{user.email}"
          else
            @results[:errors] << "Row #{index + 1}: #{user.errors.full_messages.join(', ')}"
            raise ActiveRecord::Rollback if params[:stop_on_error] == '1'
          end
        end
      end
      
      if @results[:errors].empty?
        redirect_to admin_users_path, notice: "Successfully created #{@results[:success].count} users"
      else
        flash.now[:alert] = "Import completed with #{@results[:errors].count} errors"
        render :batch_new
      end
    rescue => e
      flash.now[:alert] = "Import failed: #{e.message}"
      render :batch_new
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:email, :password, :role, :lasid, :first_name, :last_name, :nickname, :date_of_birth)
    end
  end
end