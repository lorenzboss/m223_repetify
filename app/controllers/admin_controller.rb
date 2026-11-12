class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_user, only: [ :show, :edit, :update, :destroy, :suspend, :unsuspend, :make_admin, :remove_admin, :change_email ]

  def index
    @users = User.order(admin: :desc, created_at: :desc)
    user_counts = User.group(:admin, :suspended).count
    @stats = {
      total_users: user_counts.values.sum,
      admin_users: user_counts.sum { |(admin, _), count| admin ? count : 0 },
      suspended_users: user_counts.sum { |(_, suspended), count| suspended ? count : 0 },
      active_users: user_counts.sum { |(_, suspended), count| suspended ? 0 : count }
    }
  end

  def activity_log
    versions_query = PaperTrail::Version.order(created_at: :desc)

    @pagy, @versions = pagy(:offset, versions_query, limit: 20)
    @total_versions_count = @pagy.count

    # Preload user emails for the displayed versions to avoid a DB call per row in the view
    # whodunnit is stored as a string (user id) in PaperTrail; convert to integers safely
    user_ids = @versions.map(&:whodunnit).compact.map { |w| w.to_s.match?(/\A\d+\z/) ? w.to_i : nil }.compact.uniq
    @version_user_emails = user_ids.any? ? User.where(id: user_ids).pluck(:id, :email).to_h : {}
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
