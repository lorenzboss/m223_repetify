class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_user, only: [ :show, :edit, :update, :destroy, :suspend, :unsuspend, :make_admin, :remove_admin, :change_email ]

  def index
    @users = User.order(admin: :desc, created_at: :desc)
    @stats = {
      total_users: User.count,
      admin_users: User.admins.count,
      suspended_users: User.suspended.count,
      active_users: User.active.count
    }
  end

  def activity_log
    @versions = PaperTrail::Version.includes(:item)
      .order(created_at: :desc)
      .limit(100) # Begrenze auf die letzten 100 Einträge
  end

  def show
    # Show individual user details
  end

  def edit
    # Edit user form
  end

  def update
    if @user.update(user_params)
      redirect_to admin_index_path, notice: "Benutzer wurde erfolgreich aktualisiert."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to admin_index_path, alert: "Du kannst dich nicht selbst löschen."
      return
    end

    @user.destroy
    redirect_to admin_index_path, notice: "Benutzer wurde erfolgreich gelöscht."
  end

  def suspend
    if @user == current_user
      redirect_to admin_index_path, alert: "Du kannst dich nicht selbst sperren."
      return
    end

    @user.update(suspended: true)
    redirect_to admin_index_path, notice: "Benutzer wurde erfolgreich gesperrt."
  end

  def unsuspend
    @user.update(suspended: false)
    redirect_to admin_index_path, notice: "Benutzer wurde erfolgreich entsperrt."
  end

  def make_admin
    if @user == current_user
      redirect_to admin_index_path, alert: "Du bist bereits Administrator."
      return
    end

    @user.update(admin: true)
    redirect_to admin_index_path, notice: "Benutzer wurde zum Administrator gemacht."
  end

  def remove_admin
    if @user == current_user
      redirect_to admin_index_path, alert: "Du kannst dir nicht selbst die Admin-Rechte entziehen."
      return
    end

    @user.update(admin: false)
    redirect_to admin_index_path, notice: "Administrator-Rechte wurden entzogen."
  end

  def change_email
    new_email = params[:new_email]

    if new_email.blank?
      redirect_to admin_index_path, alert: "E-Mail-Adresse darf nicht leer sein."
      return
    end

    if @user == current_user
      redirect_to admin_index_path, alert: "Du kannst deine eigene E-Mail-Adresse hier nicht ändern."
      return
    end

    # Prüfe ob die E-Mail bereits verwendet wird
    if User.where(email: new_email).where.not(id: @user.id).exists?
      redirect_to admin_index_path, alert: "Diese E-Mail-Adresse wird bereits verwendet."
      return
    end

    old_email = @user.email
    if @user.update(email: new_email)
      redirect_to admin_index_path, notice: "E-Mail-Adresse von #{old_email} wurde erfolgreich zu #{new_email} geändert."
    else
      redirect_to admin_index_path, alert: "Fehler beim Ändern der E-Mail-Adresse: #{@user.errors.full_messages.join(', ')}"
    end
  end

  private

  def ensure_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "Zugriff verweigert. Nur Administratoren haben Zugriff."
    end
  end

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :admin, :suspended)
  end
end
