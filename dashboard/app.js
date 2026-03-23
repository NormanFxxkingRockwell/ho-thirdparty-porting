const summaryCards = document.getElementById("summaryCards");
const latestTableBody = document.getElementById("latestTableBody");
const historyList = document.getElementById("historyList");
const meta = document.getElementById("meta");
const refreshBtn = document.getElementById("refreshBtn");
const autoRefresh = document.getElementById("autoRefresh");
const searchInput = document.getElementById("searchInput");
const statusFilter = document.getElementById("statusFilter");

let latestPayload = null;
let timer = null;

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function statusClass(value) {
  switch (value) {
    case "已完成":
      return "status status-done";
    case "适配中":
    case "源码已拉取":
    case "已适配":
    case "已编译未测试":
      return "status status-adapting";
    case "方案待审批":
      return "status status-pending";
    case "失败":
      return "status status-failed";
    case "异常":
      return "status status-anomaly";
    default:
      return "status status-default";
  }
}

function renderSummary(summary) {
  const items = [
    ["总库数", summary.total],
    ["已完成", summary.done],
    ["待审批", summary.pending_approval],
    ["适配中", summary.adapting + summary.adapted],
    ["已编译未测试", summary.built_not_tested],
    ["失败", summary.failed],
    ["异常", summary.anomaly],
  ];
  summaryCards.innerHTML = items
    .map(
      ([label, value]) =>
        `<div class="card"><h3>${escapeHtml(label)}</h3><strong>${escapeHtml(value)}</strong></div>`
    )
    .join("");
}

function buildPathLinks(item) {
  const links = [];
  if (item.paths.source_dir) {
    links.push(`<a href="/browse?path=${encodeURIComponent(item.paths.source_dir)}">源码</a>`);
  }
  if (item.paths.report_dir) {
    links.push(`<a href="/browse?path=${encodeURIComponent(item.paths.report_dir)}">报告目录</a>`);
  }
  if (item.paths.output_dir) {
    links.push(`<a href="/browse?path=${encodeURIComponent(item.paths.output_dir)}">产物目录</a>`);
  }
  if (item.paths.build_report) {
    links.push(`<a href="/browse?path=${encodeURIComponent(item.paths.build_report)}">build-report</a>`);
  }
  return `<div class="path-links small">${links.join(" | ")}</div>`;
}

function renderLatestTable(items) {
  const keyword = searchInput.value.trim().toLowerCase();
  const filter = statusFilter.value;
  const filtered = items.filter((item) => {
    const hitKeyword = !keyword || item.lib_name.toLowerCase().includes(keyword);
    const hitStatus = !filter || item.derived_status === filter;
    return hitKeyword && hitStatus;
  });

  latestTableBody.innerHTML = filtered
    .map((item) => {
      const notes = [];
      if (item.note) {
        notes.push(`<div>${escapeHtml(item.note)}</div>`);
      }
      if (item.anomalies.length) {
        notes.push(
          `<div class="small"><strong>异常：</strong>${item.anomalies.map(escapeHtml).join("；")}</div>`
        );
      }
      return `
        <tr>
          <td>
            <strong>${escapeHtml(item.lib_name)}</strong>
            <div class="small muted">${escapeHtml(item.version || "-")}</div>
          </td>
          <td><span class="${statusClass(item.derived_status)}">${escapeHtml(item.derived_status)}</span></td>
          <td class="small">
            ${escapeHtml(item.approval_required)} / ${escapeHtml(item.approval_result)}
          </td>
          <td>${escapeHtml(item.adaptation_status || "待处理")}</td>
          <td>${escapeHtml(item.build_status || "待处理")}</td>
          <td>${escapeHtml(item.test_status || "待处理")}</td>
          <td>${item.artifacts.has_so ? "是" : "否"}</td>
          <td>${item.artifacts.has_binary ? "是" : "否"}</td>
          <td>${buildPathLinks(item)}</td>
          <td class="small">${notes.join("") || '<span class="muted">-</span>'}</td>
        </tr>
      `;
    })
    .join("");
}

function renderHistory(history) {
  historyList.innerHTML = history
    .map((batch) => {
      const rows = batch.rows
        .map(
          (row) =>
            `<li>${escapeHtml(row.lib_name)}：${escapeHtml(row.adaptation_status)}/${escapeHtml(
              row.build_status
            )}/${escapeHtml(row.test_status)}${row.note ? `，${escapeHtml(row.note)}` : ""}</li>`
        )
        .join("");
      const summary = batch.summary
        .map((line) => `<li>${escapeHtml(line)}</li>`)
        .join("");
      return `
        <div class="history-item">
          <h3>${escapeHtml(batch.date)}</h3>
          <div class="small"><a class="history-link" href="/browse?path=${encodeURIComponent(
            batch.path
          )}">打开批次报告</a></div>
          <div class="small muted">库：${escapeHtml(batch.libs.join("、")) || "-"}</div>
          ${rows ? `<ul>${rows}</ul>` : ""}
          ${summary ? `<ul>${summary}</ul>` : ""}
        </div>
      `;
    })
    .join("");
}

function refreshFilterOptions(items) {
  const current = statusFilter.value;
  const states = Array.from(new Set(items.map((item) => item.derived_status)));
  statusFilter.innerHTML =
    '<option value="">全部状态</option>' +
    states.map((state) => `<option value="${escapeHtml(state)}">${escapeHtml(state)}</option>`).join("");
  statusFilter.value = states.includes(current) ? current : "";
}

async function loadStatus() {
  const response = await fetch("/api/status", { cache: "no-store" });
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`);
  }
  latestPayload = await response.json();
  meta.textContent = `任务表：${latestPayload.task_files?.length || 0} 份 | 最新：${latestPayload.latest_task_file || "无"} | 最后刷新：${latestPayload.generated_at}`;
  renderSummary(latestPayload.summary);
  refreshFilterOptions(latestPayload.current_items);
  renderLatestTable(latestPayload.current_items);
  renderHistory(latestPayload.history);
}

function startAutoRefresh() {
  if (timer) {
    clearInterval(timer);
    timer = null;
  }
  if (autoRefresh.checked) {
    timer = setInterval(() => {
      loadStatus().catch((error) => {
        meta.textContent = `刷新失败：${error.message}`;
      });
    }, 5000);
  }
}

refreshBtn.addEventListener("click", () => {
  loadStatus().catch((error) => {
    meta.textContent = `刷新失败：${error.message}`;
  });
});

autoRefresh.addEventListener("change", startAutoRefresh);
searchInput.addEventListener("input", () => {
  if (latestPayload) renderLatestTable(latestPayload.current_items);
});
statusFilter.addEventListener("change", () => {
  if (latestPayload) renderLatestTable(latestPayload.current_items);
});

loadStatus()
  .then(startAutoRefresh)
  .catch((error) => {
    meta.textContent = `初始化失败：${error.message}`;
  });
