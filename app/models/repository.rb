# frozen_string_literal: true

class Repository < ApplicationRecord
  include EncryptedToken

  validates_presence_of :name, :url

  has_many :refs, dependent: :destroy
  has_many :permissions, class_name: 'RepositoryPermission', dependent: :destroy
  has_many :users, through: :permissions
  has_many :commits, dependent: :destroy
  has_many :webhooks, dependent: :destroy

  SERVERTYPE_KLASS = {
      'perforce' => P4ServerType,
      'svn' => ::SvnServerType,
  }.freeze

  def branches
    refs.branch
  end

  def tags
    refs.tag
  end

  def ownerName
    Organization.find(self.owner_id)&.ane
  rescue
    ''
  end

  def repo(username = nil, token = nil)
    kklass = SERVERTYPE_KLASS[self.server_type]
    kklass&.bare_repo(self, username, token)
  end

  def commit_info_from_webhook(payload, username, token)
    return unless payload.key?(:change_root) && username && token

    repo(username, token).commit_info(payload[:change_root], payload[:username], id)
  end

  def file_contents(ref, path)
    repo.file_contents(ref, path)
  end
end
