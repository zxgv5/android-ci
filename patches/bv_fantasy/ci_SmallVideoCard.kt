package dev.aaa1115910.bv.tv.component.videocard

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import androidx.tv.material3.Card
import androidx.tv.material3.CardDefaults
import androidx.tv.material3.MaterialTheme
import dev.aaa1115910.bv.R
import dev.aaa1115910.bv.data.entity.DynamicVideoItem
import dev.aaa1115910.bv.util.ModifierExtends.focusedBorder
import dev.aaa1115910.bv.util.ModifierExtends.focusedScale

/**
 * TV端小视频卡片（动态/UP空间/推荐页通用）
 * 补充：焦点状态、长按/菜单键回调、充电视频闪电图标
 */
@Composable
fun SmallVideoCard(
    modifier: Modifier = Modifier,
    video: DynamicVideoItem,
    onVideoClick: () -> Unit,
    onLongClick: () -> Unit, // 长按确认键进UP空间
    onMenuKeyClick: () -> Unit // 菜单键打开已关注UP列表
) {
    Card(
        modifier = modifier.size(240.dp, 180.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface,
            focusedContainerColor = MaterialTheme.colorScheme.surface
        ),
        onClick = onVideoClick,
        onLongClick = onLongClick,
        onKeyPreImeEvent = { keyEvent ->
            // 监听菜单键（TV遥控器菜单键）
            if (keyEvent.key == androidx.compose.ui.input.key.Key.Menu && 
                keyEvent.type == androidx.compose.ui.input.key.KeyEventType.KeyDown) {
                onMenuKeyClick()
                return@onKeyPreImeEvent true
            }
            false
        }
    ) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = androidx.compose.ui.Alignment.Center
        ) {
            // 视频封面（复用项目原有AsyncImage逻辑）
            AsyncImage(
                model = video.cover,
                contentDescription = video.title,
                modifier = Modifier.fillMaxSize(),
                contentScale = androidx.compose.ui.layout.ContentScale.Crop
            )

            // 充电视频右上角闪电图标（项目需求）
            if (video.isChargingVideo) {
                Icon(
                    modifier = Modifier
                        .size(24.dp)
                        .align(androidx.compose.ui.Alignment.TopEnd)
                        .padding(8.dp),
                    painter = painterResource(id = R.drawable.ic_lightning),
                    contentDescription = "充电视频",
                    tint = MaterialTheme.colorScheme.primary
                )
            }

            // 视频时长（复用项目原有时长格式化逻辑）
            Text(
                modifier = Modifier
                    .align(androidx.compose.ui.Alignment.BottomEnd)
                    .padding(8.dp)
                    .background(MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f))
                    .padding(horizontal = 4.dp, vertical = 2.dp),
                text = video.duration.formatHourMinSec(),
                color = MaterialTheme.colorScheme.onSurface,
                style = MaterialTheme.typography.bodySmall
            )
        }
    }
}